--
-- PostgreSQL database dump
--

\restrict wilZhkpVewNuAmf7wA3aRDZmcVnBIer3k1Oa5hmTY2Ojc5jYg5sJANKfoCvrOKz

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-09 22:48:06

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 2 (class 3079 OID 34379)
-- Name: pgcrypto; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA public;


--
-- TOC entry 5262 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 940 (class 1247 OID 34458)
-- Name: finding_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.finding_status AS ENUM (
    'open',
    'in_progress',
    'resolved',
    'accepted_risk',
    'false_positive'
);


ALTER TYPE public.finding_status OWNER TO postgres;

--
-- TOC entry 943 (class 1247 OID 34470)
-- Name: log_level; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.log_level AS ENUM (
    'debug',
    'info',
    'warning',
    'error',
    'security'
);


ALTER TYPE public.log_level OWNER TO postgres;

--
-- TOC entry 937 (class 1247 OID 34446)
-- Name: risk_severity; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.risk_severity AS ENUM (
    'info',
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public.risk_severity OWNER TO postgres;

--
-- TOC entry 931 (class 1247 OID 34426)
-- Name: scan_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scan_status AS ENUM (
    'queued',
    'running',
    'completed',
    'failed',
    'cancelled'
);


ALTER TYPE public.scan_status OWNER TO postgres;

--
-- TOC entry 934 (class 1247 OID 34438)
-- Name: scan_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scan_type AS ENUM (
    'passive',
    'active',
    'authenticated'
);


ALTER TYPE public.scan_type OWNER TO postgres;

--
-- TOC entry 928 (class 1247 OID 34418)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'analyst',
    'viewer'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 277 (class 1255 OID 34608)
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.set_updated_at() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 236 (class 1259 OID 34577)
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    user_id uuid,
    scan_id uuid,
    level public.log_level DEFAULT 'info'::public.log_level NOT NULL,
    action character varying(150) NOT NULL,
    message text NOT NULL,
    ip_address inet,
    user_agent text,
    details jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT activity_logs_action_not_blank CHECK ((length(btrim((action)::text)) > 0))
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- TOC entry 5263 (class 0 OID 0)
-- Dependencies: 236
-- Name: TABLE activity_logs; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.activity_logs IS 'Append-only audit and intrusion-detection event trail.';


--
-- TOC entry 235 (class 1259 OID 34576)
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

ALTER TABLE public.activity_logs ALTER COLUMN id ADD GENERATED ALWAYS AS IDENTITY (
    SEQUENCE NAME public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);


--
-- TOC entry 225 (class 1259 OID 33941)
-- Name: ai_predictions; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.ai_predictions (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    input_type character varying(100) NOT NULL,
    prediction character varying(150) NOT NULL,
    confidence double precision NOT NULL,
    model_name character varying(100) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.ai_predictions OWNER TO postgres;

--
-- TOC entry 224 (class 1259 OID 33940)
-- Name: ai_predictions_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.ai_predictions_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.ai_predictions_id_seq OWNER TO postgres;

--
-- TOC entry 5264 (class 0 OID 0)
-- Dependencies: 224
-- Name: ai_predictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ai_predictions_id_seq OWNED BY public.ai_predictions.id;


--
-- TOC entry 234 (class 1259 OID 34541)
-- Name: findings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.findings (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scan_id uuid NOT NULL,
    vulnerability_type character varying(150) NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    severity public.risk_severity NOT NULL,
    cvss_score numeric(3,1),
    cwe_id character varying(20),
    affected_url text,
    parameter_name character varying(200),
    evidence jsonb DEFAULT '{}'::jsonb NOT NULL,
    remediation text,
    status public.finding_status DEFAULT 'open'::public.finding_status NOT NULL,
    ai_confidence numeric(4,3),
    detected_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT findings_ai_confidence_check CHECK (((ai_confidence >= 0.000) AND (ai_confidence <= 1.000))),
    CONSTRAINT findings_cvss_score_check CHECK (((cvss_score >= 0.0) AND (cvss_score <= 10.0))),
    CONSTRAINT findings_resolved_at_valid CHECK (((resolved_at IS NULL) OR (resolved_at >= detected_at))),
    CONSTRAINT findings_title_not_blank CHECK ((length(btrim((title)::text)) > 0))
);


ALTER TABLE public.findings OWNER TO postgres;

--
-- TOC entry 5265 (class 0 OID 0)
-- Dependencies: 234
-- Name: TABLE findings; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.findings IS 'Vulnerabilities found during a scan, including AI classification metadata.';


--
-- TOC entry 229 (class 1259 OID 33982)
-- Name: reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reports (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    scan_summary text,
    security_findings text,
    ai_analysis text,
    intrusion_analysis text,
    recommendations text,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.reports OWNER TO postgres;

--
-- TOC entry 228 (class 1259 OID 33981)
-- Name: reports_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reports_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.reports_id_seq OWNER TO postgres;

--
-- TOC entry 5266 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reports_id_seq OWNED BY public.reports.id;


--
-- TOC entry 227 (class 1259 OID 33961)
-- Name: risk_scores; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.risk_scores (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    severity_score double precision NOT NULL,
    ai_confidence double precision NOT NULL,
    impact_score double precision NOT NULL,
    final_score double precision NOT NULL,
    priority character varying(50) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.risk_scores OWNER TO postgres;

--
-- TOC entry 226 (class 1259 OID 33960)
-- Name: risk_scores_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.risk_scores_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.risk_scores_id_seq OWNER TO postgres;

--
-- TOC entry 5267 (class 0 OID 0)
-- Dependencies: 226
-- Name: risk_scores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.risk_scores_id_seq OWNED BY public.risk_scores.id;


--
-- TOC entry 239 (class 1259 OID 34943)
-- Name: scan_endpoints; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scan_endpoints (
    id bigint NOT NULL,
    scan_id uuid NOT NULL,
    url text NOT NULL,
    http_method character varying(10) DEFAULT 'GET'::character varying NOT NULL,
    endpoint_type character varying(30) DEFAULT 'page'::character varying NOT NULL,
    depth integer DEFAULT 0 NOT NULL,
    status_code integer,
    content_type character varying(255),
    discovered_from text,
    crawl_status character varying(20) DEFAULT 'discovered'::character varying NOT NULL,
    error_message text,
    discovered_at timestamp with time zone DEFAULT now() NOT NULL,
    crawled_at timestamp with time zone,
    CONSTRAINT scan_endpoints_crawl_status_check CHECK (((crawl_status)::text = ANY ((ARRAY['discovered'::character varying, 'crawled'::character varying, 'failed'::character varying, 'skipped'::character varying])::text[]))),
    CONSTRAINT scan_endpoints_depth_check CHECK ((depth >= 0))
);


ALTER TABLE public.scan_endpoints OWNER TO postgres;

--
-- TOC entry 238 (class 1259 OID 34942)
-- Name: scan_endpoints_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scan_endpoints_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scan_endpoints_id_seq OWNER TO postgres;

--
-- TOC entry 5268 (class 0 OID 0)
-- Dependencies: 238
-- Name: scan_endpoints_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scan_endpoints_id_seq OWNED BY public.scan_endpoints.id;


--
-- TOC entry 231 (class 1259 OID 34002)
-- Name: scan_results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scan_results (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    result_type character varying(100) NOT NULL,
    title character varying(255) NOT NULL,
    description text,
    raw_data text,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.scan_results OWNER TO postgres;

--
-- TOC entry 230 (class 1259 OID 34001)
-- Name: scan_results_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scan_results_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scan_results_id_seq OWNER TO postgres;

--
-- TOC entry 5269 (class 0 OID 0)
-- Dependencies: 230
-- Name: scan_results_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scan_results_id_seq OWNED BY public.scan_results.id;


--
-- TOC entry 237 (class 1259 OID 34827)
-- Name: scan_risk_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.scan_risk_summary AS
SELECT
    NULL::uuid AS scan_id,
    NULL::uuid AS user_id,
    NULL::text AS target_url,
    NULL::character varying(20) AS scan_status,
    NULL::timestamp with time zone AS created_at,
    NULL::bigint AS total_findings,
    NULL::bigint AS critical_findings,
    NULL::bigint AS high_findings,
    NULL::bigint AS medium_findings,
    NULL::numeric AS highest_cvss_score;


ALTER VIEW public.scan_risk_summary OWNER TO postgres;

--
-- TOC entry 233 (class 1259 OID 34502)
-- Name: scans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scans (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    user_id uuid NOT NULL,
    target_url text NOT NULL,
    scan_type character varying(30) DEFAULT 'standard'::character varying NOT NULL,
    status character varying(20) DEFAULT 'queued'::character varying NOT NULL,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    error_message text,
    findings_count integer DEFAULT 0 NOT NULL,
    critical_count integer DEFAULT 0 NOT NULL,
    high_count integer DEFAULT 0 NOT NULL,
    scan_config jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    spider boolean DEFAULT true NOT NULL,
    passive boolean DEFAULT true NOT NULL,
    active boolean DEFAULT false NOT NULL,
    scope_type character varying(20) DEFAULT 'single_url'::character varying NOT NULL,
    authorization_confirmed boolean DEFAULT false NOT NULL,
    crawl_depth integer DEFAULT 5 NOT NULL,
    max_pages integer DEFAULT 500 NOT NULL,
    request_delay_ms integer DEFAULT 100 NOT NULL,
    javascript_crawling boolean DEFAULT true NOT NULL,
    follow_redirects boolean DEFAULT true NOT NULL,
    security_checks jsonb DEFAULT '["security_headers"]'::jsonb NOT NULL,
    excluded_paths jsonb DEFAULT '[]'::jsonb NOT NULL,
    authentication_type character varying(20) DEFAULT 'none'::character varying NOT NULL,
    pages_discovered integer DEFAULT 0 NOT NULL,
    requests_analyzed integer DEFAULT 0 NOT NULL,
    endpoints_found integer DEFAULT 0 NOT NULL,
    CONSTRAINT scans_active_requires_authorization CHECK (((NOT active) OR authorization_confirmed)),
    CONSTRAINT scans_completed_after_started CHECK (((completed_at IS NULL) OR (started_at IS NULL) OR (completed_at >= started_at))),
    CONSTRAINT scans_crawl_depth_check CHECK (((crawl_depth >= 1) AND (crawl_depth <= 20))),
    CONSTRAINT scans_critical_count_check CHECK ((critical_count >= 0)),
    CONSTRAINT scans_findings_count_check CHECK ((findings_count >= 0)),
    CONSTRAINT scans_high_count_check CHECK ((high_count >= 0)),
    CONSTRAINT scans_max_pages_check CHECK (((max_pages >= 1) AND (max_pages <= 10000))),
    CONSTRAINT scans_request_delay_ms_check CHECK (((request_delay_ms >= 0) AND (request_delay_ms <= 10000))),
    CONSTRAINT scans_status_valid CHECK (((status)::text = ANY ((ARRAY['queued'::character varying, 'crawling'::character varying, 'passive'::character varying, 'active'::character varying, 'analyzing'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT scans_target_url_valid CHECK ((target_url ~* '^https?://'::text))
);


ALTER TABLE public.scans OWNER TO postgres;

--
-- TOC entry 5270 (class 0 OID 0)
-- Dependencies: 233
-- Name: TABLE scans; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.scans IS 'Security scan executions initiated by users.';


--
-- TOC entry 221 (class 1259 OID 33887)
-- Name: traffic_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.traffic_logs (
    id integer NOT NULL,
    source_ip character varying(100),
    method character varying(20),
    endpoint character varying(500),
    status_code integer,
    user_agent text,
    classification character varying(50) NOT NULL,
    confidence double precision,
    created_at timestamp without time zone NOT NULL,
    scan_id uuid
);


ALTER TABLE public.traffic_logs OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 33886)
-- Name: traffic_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.traffic_logs_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.traffic_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5271 (class 0 OID 0)
-- Dependencies: 220
-- Name: traffic_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.traffic_logs_id_seq OWNED BY public.traffic_logs.id;


--
-- TOC entry 232 (class 1259 OID 34481)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    email character varying(320) NOT NULL,
    password_hash text NOT NULL,
    full_name character varying(200),
    role public.user_role DEFAULT 'analyst'::public.user_role NOT NULL,
    is_active boolean DEFAULT true NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT users_email_not_blank CHECK ((length(btrim((email)::text)) > 0))
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 5272 (class 0 OID 0)
-- Dependencies: 232
-- Name: TABLE users; Type: COMMENT; Schema: public; Owner: postgres
--

COMMENT ON TABLE public.users IS 'Application accounts. Passwords must be stored only as strong one-way hashes.';


--
-- TOC entry 223 (class 1259 OID 33920)
-- Name: vulnerabilities; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vulnerabilities (
    id integer NOT NULL,
    scan_id integer NOT NULL,
    type character varying(150) NOT NULL,
    severity character varying(50) NOT NULL,
    confidence double precision,
    description text,
    recommendation text,
    status character varying(50) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.vulnerabilities OWNER TO postgres;

--
-- TOC entry 222 (class 1259 OID 33919)
-- Name: vulnerabilities_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vulnerabilities_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vulnerabilities_id_seq OWNER TO postgres;

--
-- TOC entry 5273 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vulnerabilities_id_seq OWNED BY public.vulnerabilities.id;


--
-- TOC entry 4966 (class 2604 OID 33944)
-- Name: ai_predictions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions ALTER COLUMN id SET DEFAULT nextval('public.ai_predictions_id_seq'::regclass);


--
-- TOC entry 4968 (class 2604 OID 33985)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 4967 (class 2604 OID 33964)
-- Name: risk_scores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores ALTER COLUMN id SET DEFAULT nextval('public.risk_scores_id_seq'::regclass);


--
-- TOC entry 5009 (class 2604 OID 34946)
-- Name: scan_endpoints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints ALTER COLUMN id SET DEFAULT nextval('public.scan_endpoints_id_seq'::regclass);


--
-- TOC entry 4969 (class 2604 OID 34005)
-- Name: scan_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results ALTER COLUMN id SET DEFAULT nextval('public.scan_results_id_seq'::regclass);


--
-- TOC entry 4964 (class 2604 OID 33890)
-- Name: traffic_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs ALTER COLUMN id SET DEFAULT nextval('public.traffic_logs_id_seq'::regclass);


--
-- TOC entry 4965 (class 2604 OID 33923)
-- Name: vulnerabilities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.vulnerabilities_id_seq'::regclass);


--
-- TOC entry 5254 (class 0 OID 34577)
-- Dependencies: 236
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_id, scan_id, level, action, message, ip_address, user_agent, details, created_at) FROM stdin;
1	f747336e-23e4-45fc-8236-0c405c66d66a	2d447ca9-3046-4ba0-b3da-139c94c9b888	info	seed.created	Development seed data applied.	\N	\N	{"source": "backend/seed_data.py"}	2026-10-03 19:42:34.24247+05:30
2	010752b0-dc79-4ad4-8293-6f4f7da62c57	e3a30550-b40d-421e-852b-bcf67df007c2	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:08:41.831554+05:30
3	010752b0-dc79-4ad4-8293-6f4f7da62c57	e3a30550-b40d-421e-852b-bcf67df007c2	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:08:50.058772+05:30
4	010752b0-dc79-4ad4-8293-6f4f7da62c57	aab39262-df1c-4568-9119-03cd43ef3b6e	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:23:07.330114+05:30
5	010752b0-dc79-4ad4-8293-6f4f7da62c57	aab39262-df1c-4568-9119-03cd43ef3b6e	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "endpoints_found": 53, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:23:15.275866+05:30
6	010752b0-dc79-4ad4-8293-6f4f7da62c57	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-09 20:30:00.937002+05:30
7	010752b0-dc79-4ad4-8293-6f4f7da62c57	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 57, "endpoints_found": 19, "pages_discovered": 19, "requests_analyzed": 19}	2026-10-09 20:30:08.357829+05:30
8	010752b0-dc79-4ad4-8293-6f4f7da62c57	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://demo.owasp-juice.shop/"}	2026-10-09 21:09:01.910695+05:30
9	010752b0-dc79-4ad4-8293-6f4f7da62c57	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 4, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-09 21:09:06.450083+05:30
\.


--
-- TOC entry 5243 (class 0 OID 33941)
-- Dependencies: 225
-- Data for Name: ai_predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_predictions (id, scan_id, input_type, prediction, confidence, model_name, created_at) FROM stdin;
\.


--
-- TOC entry 5252 (class 0 OID 34541)
-- Dependencies: 234
-- Data for Name: findings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.findings (id, scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, status, ai_confidence, detected_at, resolved_at, created_at, updated_at) FROM stdin;
9cdd2e2c-12dc-4d83-8a3c-4ca0d5be8102	2d447ca9-3046-4ba0-b3da-139c94c9b888	SQL Injection	Unsanitized search parameter	Demo finding for development validation.	high	8.1	CWE-89	https://demo.example.test/search	q	{"payload": "test payload", "http_status": 500}	Use parameterized queries and server-side input validation.	open	0.943	2026-10-03 19:42:34.24247+05:30	\N	2026-10-03 19:42:34.24247+05:30	2026-10-03 19:42:34.24247+05:30
b72f51d4-e3e3-4a74-a841-9502515db2bf	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.003395+05:30	\N	2026-10-09 20:08:50.003395+05:30	2026-10-09 20:08:50.003395+05:30
d0e5a5da-26a7-4661-9249-006135da3634	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.01+05:30	\N	2026-10-09 20:08:50.01+05:30	2026-10-09 20:08:50.01+05:30
f1cce6de-9318-4f14-876a-23593b54dc94	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.010607+05:30	\N	2026-10-09 20:08:50.010607+05:30	2026-10-09 20:08:50.010607+05:30
a0b81b84-97a0-4e86-a7a1-fb02a005b2c5	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.011109+05:30	\N	2026-10-09 20:08:50.011109+05:30	2026-10-09 20:08:50.011109+05:30
53867477-99d4-4428-bc9e-a337e01ea910	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.011581+05:30	\N	2026-10-09 20:08:50.011581+05:30	2026-10-09 20:08:50.011581+05:30
a33d15ab-ef4b-4c4c-9c08-3ff6fda7c668	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.012091+05:30	\N	2026-10-09 20:08:50.012091+05:30	2026-10-09 20:08:50.012091+05:30
61287070-a5ef-47e8-ae71-39d4d5eb0498	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.012508+05:30	\N	2026-10-09 20:08:50.012508+05:30	2026-10-09 20:08:50.012508+05:30
ddeb1657-5431-42eb-8738-3eb806679a9d	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.012945+05:30	\N	2026-10-09 20:08:50.012945+05:30	2026-10-09 20:08:50.012945+05:30
2d16e91b-1074-4ab0-8030-799cb2750343	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.013314+05:30	\N	2026-10-09 20:08:50.013314+05:30	2026-10-09 20:08:50.013314+05:30
d61dd422-e851-40f1-9ddf-54f3217b7f15	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.013679+05:30	\N	2026-10-09 20:08:50.013679+05:30	2026-10-09 20:08:50.013679+05:30
5b089879-4995-43c7-82e3-878b9aae82bc	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.014041+05:30	\N	2026-10-09 20:08:50.014041+05:30	2026-10-09 20:08:50.014041+05:30
bd3c95df-1245-4042-a32d-8c84c65a5fe8	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.014402+05:30	\N	2026-10-09 20:08:50.014402+05:30	2026-10-09 20:08:50.014402+05:30
0d746421-c2f7-43d0-b52e-2d18953467c3	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.014761+05:30	\N	2026-10-09 20:08:50.014761+05:30	2026-10-09 20:08:50.014761+05:30
1f73bc10-25b9-4171-9113-d63e9fa1cb53	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.015118+05:30	\N	2026-10-09 20:08:50.015118+05:30	2026-10-09 20:08:50.015118+05:30
43b21baa-04ac-40f7-8a25-01feeada3b15	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.015453+05:30	\N	2026-10-09 20:08:50.015453+05:30	2026-10-09 20:08:50.015453+05:30
dca83274-f05d-49c3-8570-cc493b70b831	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.015784+05:30	\N	2026-10-09 20:08:50.015784+05:30	2026-10-09 20:08:50.015784+05:30
21602f92-4362-401e-a2a1-04ed0bb4e173	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.016111+05:30	\N	2026-10-09 20:08:50.016111+05:30	2026-10-09 20:08:50.016111+05:30
4ce8b0a7-287e-45d2-8af7-bc0b846e43b0	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.016444+05:30	\N	2026-10-09 20:08:50.016444+05:30	2026-10-09 20:08:50.016444+05:30
df40278b-e845-4ce6-9f71-2386391220c5	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.017103+05:30	\N	2026-10-09 20:08:50.017103+05:30	2026-10-09 20:08:50.017103+05:30
25326a5b-9d13-4577-923a-1e9eb9fd6df4	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.017466+05:30	\N	2026-10-09 20:08:50.017466+05:30	2026-10-09 20:08:50.017466+05:30
81827706-ab86-4420-96f2-cbfd870089d2	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.017864+05:30	\N	2026-10-09 20:08:50.017864+05:30	2026-10-09 20:08:50.017864+05:30
401099d4-849f-4fe8-a433-9efc7b96af47	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.018849+05:30	\N	2026-10-09 20:08:50.018849+05:30	2026-10-09 20:08:50.018849+05:30
a301afde-2a11-49f7-925c-38aab399b9cc	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.019232+05:30	\N	2026-10-09 20:08:50.019232+05:30	2026-10-09 20:08:50.019232+05:30
1080bb02-6600-40e7-93e5-1cc234181023	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.01957+05:30	\N	2026-10-09 20:08:50.01957+05:30	2026-10-09 20:08:50.01957+05:30
93bca929-4be4-49aa-a960-cf29b488f75b	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.019908+05:30	\N	2026-10-09 20:08:50.019908+05:30	2026-10-09 20:08:50.019908+05:30
7a2c360f-70aa-4a27-919d-1e1883d68ec3	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.020286+05:30	\N	2026-10-09 20:08:50.020286+05:30	2026-10-09 20:08:50.020286+05:30
02d632c7-d390-4294-bd10-f94987b10f6a	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.020615+05:30	\N	2026-10-09 20:08:50.020615+05:30	2026-10-09 20:08:50.020615+05:30
b0a34986-808d-40fe-902c-856b05f7269f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.020942+05:30	\N	2026-10-09 20:08:50.020942+05:30	2026-10-09 20:08:50.020942+05:30
60e22cb2-a4fc-4323-83b9-eaafa907b807	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/about.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.021284+05:30	\N	2026-10-09 20:08:50.021284+05:30	2026-10-09 20:08:50.021284+05:30
51a2f1a4-39f1-4ff7-ac5c-ea9bba390ba1	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/about.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.021616+05:30	\N	2026-10-09 20:08:50.021616+05:30	2026-10-09 20:08:50.021616+05:30
c889e2e7-1cd3-4a5c-b9e7-7d94990d48b9	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.022238+05:30	\N	2026-10-09 20:08:50.022238+05:30	2026-10-09 20:08:50.022238+05:30
f0ba0c44-899f-43a2-b2e9-faba71511a08	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.022669+05:30	\N	2026-10-09 20:08:50.022669+05:30	2026-10-09 20:08:50.022669+05:30
35a714e7-5fe2-48f1-9819-b90c3a3fd27f	e3a30550-b40d-421e-852b-bcf67df007c2	cookie_security	Cookie may be missing HttpOnly attribute: PHPSESSID	A Set-Cookie response appears not to include HttpOnly.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Use HttpOnly for session cookies that do not need JavaScript access.	open	0.980	2026-10-09 20:08:50.023062+05:30	\N	2026-10-09 20:08:50.023062+05:30	2026-10-09 20:08:50.023062+05:30
39810173-4b02-4192-b2f6-4ab22f0768cf	e3a30550-b40d-421e-852b-bcf67df007c2	cookie_security	Cookie may be missing SameSite attribute: PHPSESSID	A Set-Cookie response appears not to include SameSite.	info	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Set an appropriate SameSite policy and review CSRF protections.	open	0.980	2026-10-09 20:08:50.023418+05:30	\N	2026-10-09 20:08:50.023418+05:30	2026-10-09 20:08:50.023418+05:30
7fa0d73c-a3ea-4f48-b217-0216ff3b7744	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.023775+05:30	\N	2026-10-09 20:08:50.023775+05:30	2026-10-09 20:08:50.023775+05:30
cfe34e9a-3e1d-4862-bee5-c513f90caf4f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.024113+05:30	\N	2026-10-09 20:08:50.024113+05:30	2026-10-09 20:08:50.024113+05:30
2fb773d2-fe6f-47ec-b309-94596a87cea0	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.02445+05:30	\N	2026-10-09 20:08:50.02445+05:30	2026-10-09 20:08:50.02445+05:30
4985de31-d09d-421f-b026-49bd5d2ed609	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.024785+05:30	\N	2026-10-09 20:08:50.024785+05:30	2026-10-09 20:08:50.024785+05:30
7b28847d-0f8f-417e-a3dd-cff52331be04	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.025123+05:30	\N	2026-10-09 20:08:50.025123+05:30	2026-10-09 20:08:50.025123+05:30
90523680-2985-4eae-82c6-36cef000d2f9	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.025457+05:30	\N	2026-10-09 20:08:50.025457+05:30	2026-10-09 20:08:50.025457+05:30
d0ae8f63-8dff-4c4f-9565-e2c3730c8e60	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.025791+05:30	\N	2026-10-09 20:08:50.025791+05:30	2026-10-09 20:08:50.025791+05:30
4be2f8e2-4efe-436e-a021-a37f399c2901	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.026135+05:30	\N	2026-10-09 20:08:50.026135+05:30	2026-10-09 20:08:50.026135+05:30
6b9d25eb-fcf3-4e23-a408-74c9543e0103	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.026466+05:30	\N	2026-10-09 20:08:50.026466+05:30	2026-10-09 20:08:50.026466+05:30
d1e839f6-9440-4f3c-9d1b-ee19ce69d54b	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.026851+05:30	\N	2026-10-09 20:08:50.026851+05:30	2026-10-09 20:08:50.026851+05:30
4ece3b25-7d30-4960-ab0b-6a2d1d068aa0	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.027185+05:30	\N	2026-10-09 20:08:50.027185+05:30	2026-10-09 20:08:50.027185+05:30
4fd56a3f-251a-4fd3-8e0d-f22a3b88312a	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.027514+05:30	\N	2026-10-09 20:08:50.027514+05:30	2026-10-09 20:08:50.027514+05:30
02ff2e01-6b04-4456-acb3-5c24451e29c1	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.027845+05:30	\N	2026-10-09 20:08:50.027845+05:30	2026-10-09 20:08:50.027845+05:30
0b147679-e6e5-4e4a-ae88-f7b53898b1f3	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.028177+05:30	\N	2026-10-09 20:08:50.028177+05:30	2026-10-09 20:08:50.028177+05:30
a83661c5-a18c-462d-8593-14dbd500b580	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.028506+05:30	\N	2026-10-09 20:08:50.028506+05:30	2026-10-09 20:08:50.028506+05:30
f0018cd1-b9a4-4e3f-8fd2-7c0ae30618d4	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.028835+05:30	\N	2026-10-09 20:08:50.028835+05:30	2026-10-09 20:08:50.028835+05:30
99fdb1f2-a2cb-455b-9532-21ade333bc97	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.029165+05:30	\N	2026-10-09 20:08:50.029165+05:30	2026-10-09 20:08:50.029165+05:30
d1ccc31b-b2f0-4621-b9fa-b56637b6ed01	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.029495+05:30	\N	2026-10-09 20:08:50.029495+05:30	2026-10-09 20:08:50.029495+05:30
aa03a6ff-7958-481f-a083-bd4c611f8b15	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.030226+05:30	\N	2026-10-09 20:08:50.030226+05:30	2026-10-09 20:08:50.030226+05:30
0f94a3b5-a760-4194-bb5c-b2bb9e2263db	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.030567+05:30	\N	2026-10-09 20:08:50.030567+05:30	2026-10-09 20:08:50.030567+05:30
ecd78092-82c2-4ba2-91b9-e4d0bb290833	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.030902+05:30	\N	2026-10-09 20:08:50.030902+05:30	2026-10-09 20:08:50.030902+05:30
9158106d-a2ab-4547-954f-10b98f992051	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.031238+05:30	\N	2026-10-09 20:08:50.031238+05:30	2026-10-09 20:08:50.031238+05:30
85d2e002-02f0-40e1-b0a3-97bb1feb99da	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.031572+05:30	\N	2026-10-09 20:08:50.031572+05:30	2026-10-09 20:08:50.031572+05:30
516589f3-f35e-47f9-b630-76ff2323ed8e	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.031905+05:30	\N	2026-10-09 20:08:50.031905+05:30	2026-10-09 20:08:50.031905+05:30
d55070f0-3bc2-4bab-ab06-dbdb440bca9f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.032244+05:30	\N	2026-10-09 20:08:50.032244+05:30	2026-10-09 20:08:50.032244+05:30
ec04e3c0-5217-4781-a574-ac252be336bc	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.032674+05:30	\N	2026-10-09 20:08:50.032674+05:30	2026-10-09 20:08:50.032674+05:30
af31952b-b1f7-4d19-b578-91aa4921ccaf	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.033072+05:30	\N	2026-10-09 20:08:50.033072+05:30	2026-10-09 20:08:50.033072+05:30
02dc4c18-0031-49d3-880b-cad06cdf22f6	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.033548+05:30	\N	2026-10-09 20:08:50.033548+05:30	2026-10-09 20:08:50.033548+05:30
8cc12672-a96c-4ffd-8ce6-6db73df0eb35	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.033906+05:30	\N	2026-10-09 20:08:50.033906+05:30	2026-10-09 20:08:50.033906+05:30
59007858-f318-4e92-b6b4-d2a4e8b45a10	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.034271+05:30	\N	2026-10-09 20:08:50.034271+05:30	2026-10-09 20:08:50.034271+05:30
af6a94d8-72ac-4f52-b0d4-01fda5954900	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.034643+05:30	\N	2026-10-09 20:08:50.034643+05:30	2026-10-09 20:08:50.034643+05:30
4b5545ab-d45c-4a9f-90ea-ba2f9de09d66	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.034976+05:30	\N	2026-10-09 20:08:50.034976+05:30	2026-10-09 20:08:50.034976+05:30
42c8dc0e-b0a9-426e-825e-71115a725afd	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.035313+05:30	\N	2026-10-09 20:08:50.035313+05:30	2026-10-09 20:08:50.035313+05:30
ff847996-339e-4401-b3db-3647be9ea3be	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.035644+05:30	\N	2026-10-09 20:08:50.035644+05:30	2026-10-09 20:08:50.035644+05:30
bc2286a1-56a1-4eb2-8f80-d9f3c6ae2760	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.035973+05:30	\N	2026-10-09 20:08:50.035973+05:30	2026-10-09 20:08:50.035973+05:30
227f637d-5850-4ea3-8391-4d0a861101ea	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.036304+05:30	\N	2026-10-09 20:08:50.036304+05:30	2026-10-09 20:08:50.036304+05:30
acefa4c1-a193-4e5b-81ed-74c0e7536fde	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.036638+05:30	\N	2026-10-09 20:08:50.036638+05:30	2026-10-09 20:08:50.036638+05:30
2c80a153-d300-4b46-8c4a-6855e0a0288a	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.036967+05:30	\N	2026-10-09 20:08:50.036967+05:30	2026-10-09 20:08:50.036967+05:30
09703f86-4732-4b37-a950-9ea8bcf18fdc	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.037298+05:30	\N	2026-10-09 20:08:50.037298+05:30	2026-10-09 20:08:50.037298+05:30
7410f4e8-5673-4b88-813a-c16a13a3ef44	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.037625+05:30	\N	2026-10-09 20:08:50.037625+05:30	2026-10-09 20:08:50.037625+05:30
e8efdb6c-e5af-4f01-8f54-5a74d0c29946	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.038013+05:30	\N	2026-10-09 20:08:50.038013+05:30	2026-10-09 20:08:50.038013+05:30
46678247-550c-46c9-9e5f-96a82946952d	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.038919+05:30	\N	2026-10-09 20:08:50.038919+05:30	2026-10-09 20:08:50.038919+05:30
5866426d-ac59-42a5-a1a7-63cae8405edb	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.039347+05:30	\N	2026-10-09 20:08:50.039347+05:30	2026-10-09 20:08:50.039347+05:30
3d256ead-5614-4a95-8d09-13bff3a61879	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.039869+05:30	\N	2026-10-09 20:08:50.039869+05:30	2026-10-09 20:08:50.039869+05:30
24915566-7ab3-4447-a429-c2d11d04347f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.040294+05:30	\N	2026-10-09 20:08:50.040294+05:30	2026-10-09 20:08:50.040294+05:30
65842fa9-65b5-485f-baed-4ede213262bb	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.04065+05:30	\N	2026-10-09 20:08:50.04065+05:30	2026-10-09 20:08:50.04065+05:30
350e4fd4-41c5-470f-af94-6f6269a14125	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.040989+05:30	\N	2026-10-09 20:08:50.040989+05:30	2026-10-09 20:08:50.040989+05:30
3f9ab220-abbe-4ef0-afed-2d92223346fc	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.041342+05:30	\N	2026-10-09 20:08:50.041342+05:30	2026-10-09 20:08:50.041342+05:30
ad576aa1-d53b-4dcf-954f-6c121e2814ec	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.041679+05:30	\N	2026-10-09 20:08:50.041679+05:30	2026-10-09 20:08:50.041679+05:30
22f901c2-ae59-4bf3-bc6f-95eb9ed15b87	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.042013+05:30	\N	2026-10-09 20:08:50.042013+05:30	2026-10-09 20:08:50.042013+05:30
0cb7aa2a-9942-4ba3-a236-a56c0e983f1d	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.042346+05:30	\N	2026-10-09 20:08:50.042346+05:30	2026-10-09 20:08:50.042346+05:30
440909df-b069-49cf-948c-612356c563cb	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.042799+05:30	\N	2026-10-09 20:08:50.042799+05:30	2026-10-09 20:08:50.042799+05:30
a77f2310-5bf6-4d4d-8136-e507366dbf6e	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.04315+05:30	\N	2026-10-09 20:08:50.04315+05:30	2026-10-09 20:08:50.04315+05:30
813bf623-be7c-47bb-8cfb-d5996a292300	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.043485+05:30	\N	2026-10-09 20:08:50.043485+05:30	2026-10-09 20:08:50.043485+05:30
4b6d04d5-2242-494a-b51b-286838b2ac1a	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.043821+05:30	\N	2026-10-09 20:08:50.043821+05:30	2026-10-09 20:08:50.043821+05:30
15790e45-ffe0-477d-83f7-503966d9c1a1	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.044177+05:30	\N	2026-10-09 20:08:50.044177+05:30	2026-10-09 20:08:50.044177+05:30
92bfe43c-6d72-49a4-861f-a096f2484b77	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.044511+05:30	\N	2026-10-09 20:08:50.044511+05:30	2026-10-09 20:08:50.044511+05:30
eb3176b1-50c6-46c4-9deb-8175ddbe88b5	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.044841+05:30	\N	2026-10-09 20:08:50.044841+05:30	2026-10-09 20:08:50.044841+05:30
77947b68-98c4-49e8-b3dc-fc3198c8df4f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.045172+05:30	\N	2026-10-09 20:08:50.045172+05:30	2026-10-09 20:08:50.045172+05:30
54d96850-7635-45c9-8127-fa48857ea648	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.045502+05:30	\N	2026-10-09 20:08:50.045502+05:30	2026-10-09 20:08:50.045502+05:30
231d3664-0ce6-406a-9904-572ed9b3e92d	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.045938+05:30	\N	2026-10-09 20:08:50.045938+05:30	2026-10-09 20:08:50.045938+05:30
ab3795ed-d9d1-4b52-984e-cbf25fa77257	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.046392+05:30	\N	2026-10-09 20:08:50.046392+05:30	2026-10-09 20:08:50.046392+05:30
feeab71e-3230-44d1-b941-66e1f9b83d35	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.046747+05:30	\N	2026-10-09 20:08:50.046747+05:30	2026-10-09 20:08:50.046747+05:30
77335f46-c6ef-4614-816b-f02b254961f0	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.047085+05:30	\N	2026-10-09 20:08:50.047085+05:30	2026-10-09 20:08:50.047085+05:30
f6d3ec98-8860-430e-8d74-97a4cb3540b8	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.04743+05:30	\N	2026-10-09 20:08:50.04743+05:30	2026-10-09 20:08:50.04743+05:30
29e4c428-81e0-45a5-8c00-061aade91cc3	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.047805+05:30	\N	2026-10-09 20:08:50.047805+05:30	2026-10-09 20:08:50.047805+05:30
cc746920-970e-40fa-8705-22912ec2c362	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.048169+05:30	\N	2026-10-09 20:08:50.048169+05:30	2026-10-09 20:08:50.048169+05:30
efb045fc-d626-4359-ac25-333029875623	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.048511+05:30	\N	2026-10-09 20:08:50.048511+05:30	2026-10-09 20:08:50.048511+05:30
d7912578-505a-45dd-be18-2bf75f01693f	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.048871+05:30	\N	2026-10-09 20:08:50.048871+05:30	2026-10-09 20:08:50.048871+05:30
e7dbdd74-ba9f-48d2-8110-7cdfb91ef9e8	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.049208+05:30	\N	2026-10-09 20:08:50.049208+05:30	2026-10-09 20:08:50.049208+05:30
3c8eecde-b61b-4745-9ae8-2a29f2c0e648	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.049544+05:30	\N	2026-10-09 20:08:50.049544+05:30	2026-10-09 20:08:50.049544+05:30
81cd8f79-7c7d-4ee9-84fb-7d8169d457d3	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.049878+05:30	\N	2026-10-09 20:08:50.049878+05:30	2026-10-09 20:08:50.049878+05:30
4f2627e8-a758-4457-9bbe-59b3282ee4e5	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:08:50.050236+05:30	\N	2026-10-09 20:08:50.050236+05:30	2026-10-09 20:08:50.050236+05:30
abfff8b1-7355-48ad-8356-ad9f32dce6db	e3a30550-b40d-421e-852b-bcf67df007c2	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:08:50.05058+05:30	\N	2026-10-09 20:08:50.05058+05:30	2026-10-09 20:08:50.05058+05:30
49c123cb-3f22-4f00-bec9-d49c94cbd744	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.1925+05:30	\N	2026-10-09 20:23:15.1925+05:30	2026-10-09 20:23:15.1925+05:30
3308d1db-eee2-4f09-9371-2ad5964d19b3	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.200636+05:30	\N	2026-10-09 20:23:15.200636+05:30	2026-10-09 20:23:15.200636+05:30
1240474a-af3f-4ed9-915d-5e10dfdf1504	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.201403+05:30	\N	2026-10-09 20:23:15.201403+05:30	2026-10-09 20:23:15.201403+05:30
74c31d2d-9e8f-4c5c-8366-dc808c0aab13	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.202154+05:30	\N	2026-10-09 20:23:15.202154+05:30	2026-10-09 20:23:15.202154+05:30
e4b3b5d3-30cf-4ba3-af24-3078a7f5b081	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.202838+05:30	\N	2026-10-09 20:23:15.202838+05:30	2026-10-09 20:23:15.202838+05:30
fb2cd6ae-6b6a-402f-bc8a-6e62d79a2b22	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.203524+05:30	\N	2026-10-09 20:23:15.203524+05:30	2026-10-09 20:23:15.203524+05:30
c7f8b491-1b00-4bee-ac8d-4d9f67ad9e88	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.204215+05:30	\N	2026-10-09 20:23:15.204215+05:30	2026-10-09 20:23:15.204215+05:30
683b5e1d-9ea6-4d1f-8046-84fc7298e50c	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.204853+05:30	\N	2026-10-09 20:23:15.204853+05:30	2026-10-09 20:23:15.204853+05:30
f6e7f75b-744b-4915-8472-81ef60a7cbb2	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.20547+05:30	\N	2026-10-09 20:23:15.20547+05:30	2026-10-09 20:23:15.20547+05:30
1f9174ae-067f-4a9d-a1ad-304e31394792	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.206065+05:30	\N	2026-10-09 20:23:15.206065+05:30	2026-10-09 20:23:15.206065+05:30
9b827dfa-dab9-4e9f-a85d-182daac7796d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.206743+05:30	\N	2026-10-09 20:23:15.206743+05:30	2026-10-09 20:23:15.206743+05:30
3bd53668-2d13-451f-be64-4923ac05e8f6	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.207561+05:30	\N	2026-10-09 20:23:15.207561+05:30	2026-10-09 20:23:15.207561+05:30
175d63ca-75bd-41b7-b61c-26ba05728b9a	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.208237+05:30	\N	2026-10-09 20:23:15.208237+05:30	2026-10-09 20:23:15.208237+05:30
f4da0894-e48c-4d5e-b72b-add2fa953de3	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.209259+05:30	\N	2026-10-09 20:23:15.209259+05:30	2026-10-09 20:23:15.209259+05:30
70351b6b-79f5-4ff6-9a21-09316feff44a	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.209873+05:30	\N	2026-10-09 20:23:15.209873+05:30	2026-10-09 20:23:15.209873+05:30
d8e730a0-2a20-49bb-82b0-217c5ffd7d96	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.210468+05:30	\N	2026-10-09 20:23:15.210468+05:30	2026-10-09 20:23:15.210468+05:30
f107c33f-5903-42d0-9abc-621ca409bcb5	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.211091+05:30	\N	2026-10-09 20:23:15.211091+05:30	2026-10-09 20:23:15.211091+05:30
e07bdcf8-931a-42fa-a447-8328c14b2b3b	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.211683+05:30	\N	2026-10-09 20:23:15.211683+05:30	2026-10-09 20:23:15.211683+05:30
14150674-7053-4481-b2ac-926a1612470f	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.212362+05:30	\N	2026-10-09 20:23:15.212362+05:30	2026-10-09 20:23:15.212362+05:30
a221353a-48c6-49af-8ce3-0a243647aea2	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.213284+05:30	\N	2026-10-09 20:23:15.213284+05:30	2026-10-09 20:23:15.213284+05:30
32d10a1a-13e5-4699-b892-4d2562fb04ca	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.214073+05:30	\N	2026-10-09 20:23:15.214073+05:30	2026-10-09 20:23:15.214073+05:30
435eb090-6aa1-44c1-a14f-8df517bbfb1d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.214696+05:30	\N	2026-10-09 20:23:15.214696+05:30	2026-10-09 20:23:15.214696+05:30
ff610a84-8097-4b5c-b1f2-70cc852140b7	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.215314+05:30	\N	2026-10-09 20:23:15.215314+05:30	2026-10-09 20:23:15.215314+05:30
f211943a-fa93-46e2-a458-b2c19ccd0d94	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.215912+05:30	\N	2026-10-09 20:23:15.215912+05:30	2026-10-09 20:23:15.215912+05:30
b6960667-80f8-4819-978c-8ab956d972cf	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.216617+05:30	\N	2026-10-09 20:23:15.216617+05:30	2026-10-09 20:23:15.216617+05:30
ae1ef3c6-0a2b-4dd7-8f44-c4de563f48ce	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.21804+05:30	\N	2026-10-09 20:23:15.21804+05:30	2026-10-09 20:23:15.21804+05:30
3be46f45-0f77-44e8-b39b-c0cb551ee166	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.218796+05:30	\N	2026-10-09 20:23:15.218796+05:30	2026-10-09 20:23:15.218796+05:30
14689c7a-0cd8-439f-ac6e-20e10bedec69	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.219557+05:30	\N	2026-10-09 20:23:15.219557+05:30	2026-10-09 20:23:15.219557+05:30
a915cb6e-b9e2-4a0c-b9dc-5741840fedf2	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/about.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.220275+05:30	\N	2026-10-09 20:23:15.220275+05:30	2026-10-09 20:23:15.220275+05:30
d6aca8d4-aa5e-4e35-9d07-ead0385b5fde	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/about.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.220938+05:30	\N	2026-10-09 20:23:15.220938+05:30	2026-10-09 20:23:15.220938+05:30
8de037b4-0040-412e-bbcd-6c3c72de96e2	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.221587+05:30	\N	2026-10-09 20:23:15.221587+05:30	2026-10-09 20:23:15.221587+05:30
b3a819df-310a-410b-8482-46d381256af8	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.222291+05:30	\N	2026-10-09 20:23:15.222291+05:30	2026-10-09 20:23:15.222291+05:30
986e912a-6dac-4fa7-b22a-4ca474668ffb	aab39262-df1c-4568-9119-03cd43ef3b6e	cookie_security	Cookie may be missing HttpOnly attribute: PHPSESSID	A Set-Cookie response appears not to include HttpOnly.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Use HttpOnly for session cookies that do not need JavaScript access.	open	0.980	2026-10-09 20:23:15.222926+05:30	\N	2026-10-09 20:23:15.222926+05:30	2026-10-09 20:23:15.222926+05:30
2cbdd9d0-bac3-41ab-a8c0-c298601a791a	aab39262-df1c-4568-9119-03cd43ef3b6e	cookie_security	Cookie may be missing SameSite attribute: PHPSESSID	A Set-Cookie response appears not to include SameSite.	info	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Set an appropriate SameSite policy and review CSRF protections.	open	0.980	2026-10-09 20:23:15.223537+05:30	\N	2026-10-09 20:23:15.223537+05:30	2026-10-09 20:23:15.223537+05:30
d5ebeb70-3076-4497-87d5-5329e56bb914	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.224231+05:30	\N	2026-10-09 20:23:15.224231+05:30	2026-10-09 20:23:15.224231+05:30
6cff1173-b589-47a7-99a9-8411251a6cff	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.22487+05:30	\N	2026-10-09 20:23:15.22487+05:30	2026-10-09 20:23:15.22487+05:30
b241a1ec-e829-42a1-89b2-d34cd83720f9	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.225634+05:30	\N	2026-10-09 20:23:15.225634+05:30	2026-10-09 20:23:15.225634+05:30
4c6d8264-66e6-4fee-828d-2f4ccee89393	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.226454+05:30	\N	2026-10-09 20:23:15.226454+05:30	2026-10-09 20:23:15.226454+05:30
43b947c9-80a2-4da7-af06-8a6923538e31	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.227398+05:30	\N	2026-10-09 20:23:15.227398+05:30	2026-10-09 20:23:15.227398+05:30
ec5ccbcd-015d-401a-bcb9-afd878dd79d6	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.228149+05:30	\N	2026-10-09 20:23:15.228149+05:30	2026-10-09 20:23:15.228149+05:30
78db5bf2-b88f-4c6b-b939-edeb79f101a7	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.228766+05:30	\N	2026-10-09 20:23:15.228766+05:30	2026-10-09 20:23:15.228766+05:30
a6a78e19-57fe-40b4-a737-c52f0ca1d820	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.229456+05:30	\N	2026-10-09 20:23:15.229456+05:30	2026-10-09 20:23:15.229456+05:30
f9306781-e8c6-4dbc-a71c-39dfbb4e076a	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.230061+05:30	\N	2026-10-09 20:23:15.230061+05:30	2026-10-09 20:23:15.230061+05:30
1ab68308-455c-4c0b-9c29-1ef6ed8e0b3e	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.230676+05:30	\N	2026-10-09 20:23:15.230676+05:30	2026-10-09 20:23:15.230676+05:30
dfdce48d-6e70-4132-ae63-e9a6cbfb6d12	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.23142+05:30	\N	2026-10-09 20:23:15.23142+05:30	2026-10-09 20:23:15.23142+05:30
90ae9954-49cd-45dc-bcfd-998306749e1e	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.232452+05:30	\N	2026-10-09 20:23:15.232452+05:30	2026-10-09 20:23:15.232452+05:30
bfd10a79-e27f-486f-90fd-cbd8e3a6a719	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.2332+05:30	\N	2026-10-09 20:23:15.2332+05:30	2026-10-09 20:23:15.2332+05:30
d3604244-ddba-4a97-872f-24e3f522a17c	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.233948+05:30	\N	2026-10-09 20:23:15.233948+05:30	2026-10-09 20:23:15.233948+05:30
7d3e4cc5-9f14-40f0-a0d4-c458cccc48aa	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.235223+05:30	\N	2026-10-09 20:23:15.235223+05:30	2026-10-09 20:23:15.235223+05:30
002fa1d2-845e-4b7c-b0fe-93d0cf105259	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.235942+05:30	\N	2026-10-09 20:23:15.235942+05:30	2026-10-09 20:23:15.235942+05:30
204bb46c-01d3-4c98-a24e-4937691f53f5	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.236624+05:30	\N	2026-10-09 20:23:15.236624+05:30	2026-10-09 20:23:15.236624+05:30
e4cf63eb-c371-4817-9e53-d5cf3e14fb8f	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.237347+05:30	\N	2026-10-09 20:23:15.237347+05:30	2026-10-09 20:23:15.237347+05:30
c745c0ef-2bad-457a-9c10-aff895079e01	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.238048+05:30	\N	2026-10-09 20:23:15.238048+05:30	2026-10-09 20:23:15.238048+05:30
4533d4c9-4249-4379-96ff-d3061186d7cf	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.238671+05:30	\N	2026-10-09 20:23:15.238671+05:30	2026-10-09 20:23:15.238671+05:30
c2272732-4366-4234-8f62-e4b7e8c29a1d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.23927+05:30	\N	2026-10-09 20:23:15.23927+05:30	2026-10-09 20:23:15.23927+05:30
2901d9dc-0c6b-4e19-8990-4857fa9e2203	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.239861+05:30	\N	2026-10-09 20:23:15.239861+05:30	2026-10-09 20:23:15.239861+05:30
90ff0ffa-7e9b-4ca7-a810-424f9b0c877d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.240475+05:30	\N	2026-10-09 20:23:15.240475+05:30	2026-10-09 20:23:15.240475+05:30
11aa45af-f1bf-44d3-b4a8-16823d58a824	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.241065+05:30	\N	2026-10-09 20:23:15.241065+05:30	2026-10-09 20:23:15.241065+05:30
e6966561-1900-467f-8123-26313ff4e254	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.241663+05:30	\N	2026-10-09 20:23:15.241663+05:30	2026-10-09 20:23:15.241663+05:30
03a5e70f-e40f-47ec-bebe-7122ee43c16a	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.242275+05:30	\N	2026-10-09 20:23:15.242275+05:30	2026-10-09 20:23:15.242275+05:30
9479c1c6-8ca2-4538-8d99-d125854f4ec9	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.242865+05:30	\N	2026-10-09 20:23:15.242865+05:30	2026-10-09 20:23:15.242865+05:30
d9c7587d-bfdf-42be-ad87-c6041d687c99	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.243456+05:30	\N	2026-10-09 20:23:15.243456+05:30	2026-10-09 20:23:15.243456+05:30
199d1f12-538c-42de-9bd7-4c7e9e27d0a4	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.244076+05:30	\N	2026-10-09 20:23:15.244076+05:30	2026-10-09 20:23:15.244076+05:30
dbf9a271-832e-42cc-8226-0425cb917e36	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.244677+05:30	\N	2026-10-09 20:23:15.244677+05:30	2026-10-09 20:23:15.244677+05:30
3f7c0cf5-c3cc-407a-ba97-6b034b275d81	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.245261+05:30	\N	2026-10-09 20:23:15.245261+05:30	2026-10-09 20:23:15.245261+05:30
6a6dc65d-1708-4d88-9922-baf0348a1932	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.245846+05:30	\N	2026-10-09 20:23:15.245846+05:30	2026-10-09 20:23:15.245846+05:30
e39a5b20-d48e-401b-b04b-9f7cba9e8ace	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.246428+05:30	\N	2026-10-09 20:23:15.246428+05:30	2026-10-09 20:23:15.246428+05:30
ab42538c-cd0d-46e4-a849-e1c571032bf7	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.247269+05:30	\N	2026-10-09 20:23:15.247269+05:30	2026-10-09 20:23:15.247269+05:30
64150945-2a1e-40f3-94ee-1dbaac5d6cbe	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.248033+05:30	\N	2026-10-09 20:23:15.248033+05:30	2026-10-09 20:23:15.248033+05:30
69cc0d8f-9a23-473e-821e-19dca14f7234	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.24874+05:30	\N	2026-10-09 20:23:15.24874+05:30	2026-10-09 20:23:15.24874+05:30
a771fd94-95b8-4732-b360-2544d7d75c23	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.249485+05:30	\N	2026-10-09 20:23:15.249485+05:30	2026-10-09 20:23:15.249485+05:30
3911bea5-5f04-455d-b67c-fb4f43f8200e	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.25012+05:30	\N	2026-10-09 20:23:15.25012+05:30	2026-10-09 20:23:15.25012+05:30
7638f76c-4717-4c8e-9131-5e65da39410e	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.250713+05:30	\N	2026-10-09 20:23:15.250713+05:30	2026-10-09 20:23:15.250713+05:30
5e4d7454-298f-4d23-b9d9-55409063ea73	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.251303+05:30	\N	2026-10-09 20:23:15.251303+05:30	2026-10-09 20:23:15.251303+05:30
567a99e8-5da8-499a-a394-ba48dafd7f08	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.251957+05:30	\N	2026-10-09 20:23:15.251957+05:30	2026-10-09 20:23:15.251957+05:30
76169922-9fe5-4536-8187-4663f0000574	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.252629+05:30	\N	2026-10-09 20:23:15.252629+05:30	2026-10-09 20:23:15.252629+05:30
9240d2ba-80fe-4e62-b904-d5722df8399d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.253234+05:30	\N	2026-10-09 20:23:15.253234+05:30	2026-10-09 20:23:15.253234+05:30
f39fa5e5-5f19-4d14-b300-f46c14ff0d22	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.25383+05:30	\N	2026-10-09 20:23:15.25383+05:30	2026-10-09 20:23:15.25383+05:30
0685e707-d867-4250-b086-8626a870cf3f	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.254419+05:30	\N	2026-10-09 20:23:15.254419+05:30	2026-10-09 20:23:15.254419+05:30
1851003b-27ca-4e40-b975-644e73f90abc	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.255006+05:30	\N	2026-10-09 20:23:15.255006+05:30	2026-10-09 20:23:15.255006+05:30
53ab161c-2b1c-45c6-8b82-bef9c941e071	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.255601+05:30	\N	2026-10-09 20:23:15.255601+05:30	2026-10-09 20:23:15.255601+05:30
c8df1e97-1621-4bad-bbd1-abf793122bfe	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.256187+05:30	\N	2026-10-09 20:23:15.256187+05:30	2026-10-09 20:23:15.256187+05:30
cea54e75-c8b3-4fce-ac81-fd70eaa6f8a6	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.256948+05:30	\N	2026-10-09 20:23:15.256948+05:30	2026-10-09 20:23:15.256948+05:30
61576848-f2e4-4c11-9661-f5d695819eae	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.25794+05:30	\N	2026-10-09 20:23:15.25794+05:30	2026-10-09 20:23:15.25794+05:30
405e3901-c193-4e2d-b5f9-109cd7030667	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.258558+05:30	\N	2026-10-09 20:23:15.258558+05:30	2026-10-09 20:23:15.258558+05:30
f8833092-ae6b-4fbc-825f-e8c24644d436	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.259229+05:30	\N	2026-10-09 20:23:15.259229+05:30	2026-10-09 20:23:15.259229+05:30
bf4af210-83a3-4300-a715-d99d771c409b	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.259832+05:30	\N	2026-10-09 20:23:15.259832+05:30	2026-10-09 20:23:15.259832+05:30
bafdce95-ca88-4afe-8161-2f82471dccfb	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.260455+05:30	\N	2026-10-09 20:23:15.260455+05:30	2026-10-09 20:23:15.260455+05:30
84668d54-9741-4d46-bd56-b0e4e2173356	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.261055+05:30	\N	2026-10-09 20:23:15.261055+05:30	2026-10-09 20:23:15.261055+05:30
486c1c56-0453-4f36-854b-fcb7b8a7b1a7	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.261647+05:30	\N	2026-10-09 20:23:15.261647+05:30	2026-10-09 20:23:15.261647+05:30
1e3b25f7-0cfd-406f-b939-325b4f215093	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.26226+05:30	\N	2026-10-09 20:23:15.26226+05:30	2026-10-09 20:23:15.26226+05:30
53ded4ec-e16b-4536-a576-99e48566db09	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.262848+05:30	\N	2026-10-09 20:23:15.262848+05:30	2026-10-09 20:23:15.262848+05:30
8d2b1abc-c0d5-4949-8113-3b47e8c5d95c	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.263435+05:30	\N	2026-10-09 20:23:15.263435+05:30	2026-10-09 20:23:15.263435+05:30
8ffd5344-42e7-42f5-9ba7-db14d0b0a326	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.264044+05:30	\N	2026-10-09 20:23:15.264044+05:30	2026-10-09 20:23:15.264044+05:30
69ef4b1e-a3ac-48eb-b316-3f32bb3553a2	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.264765+05:30	\N	2026-10-09 20:23:15.264765+05:30	2026-10-09 20:23:15.264765+05:30
dd2217e2-3d63-4f28-9210-4f5ca9b81c4d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.265369+05:30	\N	2026-10-09 20:23:15.265369+05:30	2026-10-09 20:23:15.265369+05:30
fe212618-da07-4ecb-b7c4-44ceb45536b3	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.265958+05:30	\N	2026-10-09 20:23:15.265958+05:30	2026-10-09 20:23:15.265958+05:30
be0ba59b-b998-436f-9ec0-2b6579d88799	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.266633+05:30	\N	2026-10-09 20:23:15.266633+05:30	2026-10-09 20:23:15.266633+05:30
dfe7d4cb-fc5b-4ad0-a3e0-efc13c6927e5	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.267428+05:30	\N	2026-10-09 20:23:15.267428+05:30	2026-10-09 20:23:15.267428+05:30
17089db4-3d27-4cc4-b046-d7472f811978	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.268066+05:30	\N	2026-10-09 20:23:15.268066+05:30	2026-10-09 20:23:15.268066+05:30
98e67bb2-cf3b-4646-9f26-84608c23886a	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.268743+05:30	\N	2026-10-09 20:23:15.268743+05:30	2026-10-09 20:23:15.268743+05:30
bb17a50c-d01c-4cc5-b464-8c4fba3585e1	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.269447+05:30	\N	2026-10-09 20:23:15.269447+05:30	2026-10-09 20:23:15.269447+05:30
7aeffda1-6c63-4b61-806b-63faf632a755	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.270118+05:30	\N	2026-10-09 20:23:15.270118+05:30	2026-10-09 20:23:15.270118+05:30
04ffa8fa-048c-4c79-9950-5bb1cecfbf5d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.270807+05:30	\N	2026-10-09 20:23:15.270807+05:30	2026-10-09 20:23:15.270807+05:30
e3cf3d83-a197-49db-ab85-3060fb759e5b	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.271662+05:30	\N	2026-10-09 20:23:15.271662+05:30	2026-10-09 20:23:15.271662+05:30
ee58b0e5-70f6-4fb2-95a2-936491037ea8	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.272385+05:30	\N	2026-10-09 20:23:15.272385+05:30	2026-10-09 20:23:15.272385+05:30
cadf11bb-4f4c-4661-b424-6ca73736cdbc	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 20:23:15.273072+05:30	\N	2026-10-09 20:23:15.273072+05:30	2026-10-09 20:23:15.273072+05:30
1de88d4f-0917-486e-8ad8-1d2439a9610d	aab39262-df1c-4568-9119-03cd43ef3b6e	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:23:15.273761+05:30	\N	2026-10-09 20:23:15.273761+05:30	2026-10-09 20:23:15.273761+05:30
6e44e37f-27d8-45aa-be07-e1476d2041e4	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.308303+05:30	\N	2026-10-09 20:30:08.308303+05:30	2026-10-09 20:30:08.308303+05:30
1d2a7a55-ec4f-401a-a46e-df22ad91a407	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.316499+05:30	\N	2026-10-09 20:30:08.316499+05:30	2026-10-09 20:30:08.316499+05:30
17e351fb-27c9-4ea2-a446-12218c930664	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.317353+05:30	\N	2026-10-09 20:30:08.317353+05:30	2026-10-09 20:30:08.317353+05:30
ea607aab-2fbe-40a3-a780-6d34a6a46336	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.318114+05:30	\N	2026-10-09 20:30:08.318114+05:30	2026-10-09 20:30:08.318114+05:30
006f0554-b721-40c9-b541-737718780a54	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.31883+05:30	\N	2026-10-09 20:30:08.31883+05:30	2026-10-09 20:30:08.31883+05:30
083d8032-ef73-4902-95c9-3c52f5823f70	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.319518+05:30	\N	2026-10-09 20:30:08.319518+05:30	2026-10-09 20:30:08.319518+05:30
d65336aa-e32a-42e5-b35d-053d2df2dad6	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/video	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.320204+05:30	\N	2026-10-09 20:30:08.320204+05:30	2026-10-09 20:30:08.320204+05:30
afe701af-02ed-4889-864f-255e219db611	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/video	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.320891+05:30	\N	2026-10-09 20:30:08.320891+05:30	2026-10-09 20:30:08.320891+05:30
7fffc7ce-ede6-4d52-85b5-916293435940	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/video	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.32154+05:30	\N	2026-10-09 20:30:08.32154+05:30	2026-10-09 20:30:08.32154+05:30
156f31d2-b39b-49c9-913e-902b7c283c5f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/about	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.322175+05:30	\N	2026-10-09 20:30:08.322175+05:30	2026-10-09 20:30:08.322175+05:30
f22aace2-f403-4c4c-84ec-0f644f459293	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/about	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.323259+05:30	\N	2026-10-09 20:30:08.323259+05:30	2026-10-09 20:30:08.323259+05:30
bc6c9eb1-b94e-4b37-9b93-af8cce0901b9	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/about	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.324209+05:30	\N	2026-10-09 20:30:08.324209+05:30	2026-10-09 20:30:08.324209+05:30
8e18a0d1-a9bd-4fca-a371-bb604748813e	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/contact	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.32495+05:30	\N	2026-10-09 20:30:08.32495+05:30	2026-10-09 20:30:08.32495+05:30
8272d94f-60d5-4b36-9d0f-e77434db27b8	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/contact	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.32562+05:30	\N	2026-10-09 20:30:08.32562+05:30	2026-10-09 20:30:08.32562+05:30
23dd40cc-a1c8-4636-9109-21fc35f89027	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/contact	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.32627+05:30	\N	2026-10-09 20:30:08.32627+05:30	2026-10-09 20:30:08.32627+05:30
b4114110-7cc2-4059-9b3b-54374642a997	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/carrer	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.326904+05:30	\N	2026-10-09 20:30:08.326904+05:30	2026-10-09 20:30:08.326904+05:30
de3dafb9-52f7-408b-a224-e7053bf5ae0f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/carrer	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.327581+05:30	\N	2026-10-09 20:30:08.327581+05:30	2026-10-09 20:30:08.327581+05:30
4cd01cf4-1d34-4705-aca8-0ba306498b28	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/carrer	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.328247+05:30	\N	2026-10-09 20:30:08.328247+05:30	2026-10-09 20:30:08.328247+05:30
cb584d8e-c059-4594-83fb-6c128b236d35	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.329059+05:30	\N	2026-10-09 20:30:08.329059+05:30	2026-10-09 20:30:08.329059+05:30
fd8d9e59-4807-45b4-9f9c-31d2b1f274af	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.329718+05:30	\N	2026-10-09 20:30:08.329718+05:30	2026-10-09 20:30:08.329718+05:30
09183712-7d3e-42e1-a093-e2b75a890603	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.330381+05:30	\N	2026-10-09 20:30:08.330381+05:30	2026-10-09 20:30:08.330381+05:30
eac8207f-d33a-4352-9951-85f934f121ad	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.331453+05:30	\N	2026-10-09 20:30:08.331453+05:30	2026-10-09 20:30:08.331453+05:30
3e0461dc-f133-435c-9df7-29d619ce1403	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.332115+05:30	\N	2026-10-09 20:30:08.332115+05:30	2026-10-09 20:30:08.332115+05:30
005e14c5-fa09-4062-896d-9a6a16111d48	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.332759+05:30	\N	2026-10-09 20:30:08.332759+05:30	2026-10-09 20:30:08.332759+05:30
7c4fad96-b6aa-4dc6-857d-ac912cafe2bb	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.333501+05:30	\N	2026-10-09 20:30:08.333501+05:30	2026-10-09 20:30:08.333501+05:30
44159f2d-79f7-43e3-af61-9c8911799ce0	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.334479+05:30	\N	2026-10-09 20:30:08.334479+05:30	2026-10-09 20:30:08.334479+05:30
d19dc2da-d9cc-49bf-8b0e-64d8559dd10b	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.335269+05:30	\N	2026-10-09 20:30:08.335269+05:30	2026-10-09 20:30:08.335269+05:30
42af23da-13d2-4f30-8b02-0282fca270fa	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.335945+05:30	\N	2026-10-09 20:30:08.335945+05:30	2026-10-09 20:30:08.335945+05:30
6ca11e0f-d0f1-42bd-9713-c57eecb949b1	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.336612+05:30	\N	2026-10-09 20:30:08.336612+05:30	2026-10-09 20:30:08.336612+05:30
db41cbc1-b06a-4864-bd9f-aecf8e6f5583	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.337248+05:30	\N	2026-10-09 20:30:08.337248+05:30	2026-10-09 20:30:08.337248+05:30
3d19c679-3c6e-4308-946a-ece68ba97766	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.337887+05:30	\N	2026-10-09 20:30:08.337887+05:30	2026-10-09 20:30:08.337887+05:30
352284e7-63b2-414c-9eff-6eb4edb39674	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.338538+05:30	\N	2026-10-09 20:30:08.338538+05:30	2026-10-09 20:30:08.338538+05:30
0dffd973-10d9-4be6-85a0-deeace51b8fd	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.339166+05:30	\N	2026-10-09 20:30:08.339166+05:30	2026-10-09 20:30:08.339166+05:30
501a6ea1-0dd1-4b9c-8d2a-63836a08f4a8	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/loya	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.339822+05:30	\N	2026-10-09 20:30:08.339822+05:30	2026-10-09 20:30:08.339822+05:30
56a94e29-123d-41b9-a5e2-af0a07cb2fea	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/loya	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.34054+05:30	\N	2026-10-09 20:30:08.34054+05:30	2026-10-09 20:30:08.34054+05:30
155a1375-16f8-4c36-9777-8568b16d4c8f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/loya	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.34125+05:30	\N	2026-10-09 20:30:08.34125+05:30	2026-10-09 20:30:08.34125+05:30
536d20df-853d-47fc-a851-b66597a2d105	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.341879+05:30	\N	2026-10-09 20:30:08.341879+05:30	2026-10-09 20:30:08.341879+05:30
dba10112-261a-48ae-8bbc-2091fd9bdc7e	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.34255+05:30	\N	2026-10-09 20:30:08.34255+05:30	2026-10-09 20:30:08.34255+05:30
6008fe36-7c04-449e-953e-6c6fcaa1f651	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.343211+05:30	\N	2026-10-09 20:30:08.343211+05:30	2026-10-09 20:30:08.343211+05:30
34d24992-717d-448d-9551-f7281f63c3ae	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.344138+05:30	\N	2026-10-09 20:30:08.344138+05:30	2026-10-09 20:30:08.344138+05:30
179ba2ee-9516-4749-aad8-631ae0fb41fa	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.344875+05:30	\N	2026-10-09 20:30:08.344875+05:30	2026-10-09 20:30:08.344875+05:30
14b409df-af3f-4bf5-8dfb-03cecb552c92	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.345531+05:30	\N	2026-10-09 20:30:08.345531+05:30	2026-10-09 20:30:08.345531+05:30
06906925-c346-4147-8e18-5cae2002c57f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.346167+05:30	\N	2026-10-09 20:30:08.346167+05:30	2026-10-09 20:30:08.346167+05:30
1e902131-6172-4d70-892c-ca6abebc771f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.346809+05:30	\N	2026-10-09 20:30:08.346809+05:30	2026-10-09 20:30:08.346809+05:30
cee9ad38-4ecd-4f92-981a-cbf66be6e12f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.348027+05:30	\N	2026-10-09 20:30:08.348027+05:30	2026-10-09 20:30:08.348027+05:30
c9188c7d-81d1-4c62-a70c-6bf13efb52bb	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.348671+05:30	\N	2026-10-09 20:30:08.348671+05:30	2026-10-09 20:30:08.348671+05:30
36110538-1148-4bf7-871b-089d1bb43955	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.349312+05:30	\N	2026-10-09 20:30:08.349312+05:30	2026-10-09 20:30:08.349312+05:30
fa318d84-6e42-4999-ad5e-dd7d7bb51f15	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.349958+05:30	\N	2026-10-09 20:30:08.349958+05:30	2026-10-09 20:30:08.349958+05:30
2f6a867e-3025-4606-880f-7016a28ce3c3	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.350623+05:30	\N	2026-10-09 20:30:08.350623+05:30	2026-10-09 20:30:08.350623+05:30
89d5cf8d-dd5a-4a69-8093-dd6aff25bbf5	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.351246+05:30	\N	2026-10-09 20:30:08.351246+05:30	2026-10-09 20:30:08.351246+05:30
a0ada4de-92dc-49e3-b7ff-869ac62dff1a	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.351876+05:30	\N	2026-10-09 20:30:08.351876+05:30	2026-10-09 20:30:08.351876+05:30
1d5969d5-a3b7-4e9e-a8f6-23fc096934bb	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.352571+05:30	\N	2026-10-09 20:30:08.352571+05:30	2026-10-09 20:30:08.352571+05:30
abdc71b0-1119-4e92-8159-ea2296fcca6b	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.353213+05:30	\N	2026-10-09 20:30:08.353213+05:30	2026-10-09 20:30:08.353213+05:30
d19e5aa2-8392-4c19-8e6f-5cd0479e9348	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.35413+05:30	\N	2026-10-09 20:30:08.35413+05:30	2026-10-09 20:30:08.35413+05:30
09a6ac4e-e6d2-4774-92b7-311089d7c69d	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 20:30:08.354942+05:30	\N	2026-10-09 20:30:08.354942+05:30	2026-10-09 20:30:08.354942+05:30
fa3f62a4-c32b-4a3e-b444-8464a5fdbd73	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 20:30:08.355603+05:30	\N	2026-10-09 20:30:08.355603+05:30	2026-10-09 20:30:08.355603+05:30
b2bf8e59-3918-4875-b53a-198df89caa2f	25ea9f30-9c0d-4e14-8aba-ed11c26d282d	information_disclosure	Server header may disclose version information	The Server response header appears to contain version-like digits.	info	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{"server_header": "Framer/26fa766"}	Consider minimizing server-identifying response headers.	open	0.980	2026-10-09 20:30:08.35626+05:30	\N	2026-10-09 20:30:08.35626+05:30	2026-10-09 20:30:08.35626+05:30
26784ce1-8b86-437e-b212-86b1eb994f65	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	security_headers	Strict-Transport-Security header missing	The HTTPS response did not include an HSTS header.	low	\N	\N	https://demo.owasp-juice.shop/	\N	{}	Consider enabling Strict-Transport-Security after confirming HTTPS is configured correctly.	open	0.980	2026-10-09 21:09:06.43658+05:30	\N	2026-10-09 21:09:06.43658+05:30	2026-10-09 21:09:06.43658+05:30
05d02f20-6f03-454a-98ea-dff34577a481	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	security_headers	Content-Security-Policy header missing	The response did not include a Content-Security-Policy header.	low	\N	\N	https://demo.owasp-juice.shop/	\N	{}	Define a CSP appropriate for the application's scripts, styles, images, and other resources.	open	0.980	2026-10-09 21:09:06.446161+05:30	\N	2026-10-09 21:09:06.446161+05:30	2026-10-09 21:09:06.446161+05:30
e2932dff-a7d1-4276-803e-58b729944a50	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	security_headers	X-Content-Type-Options header missing	The response did not include X-Content-Type-Options.	info	\N	\N	https://demo.owasp-juice.shop/	\N	{}	Consider setting X-Content-Type-Options: nosniff.	open	0.980	2026-10-09 21:09:06.447166+05:30	\N	2026-10-09 21:09:06.447166+05:30	2026-10-09 21:09:06.447166+05:30
173aba69-7249-44b4-a1bd-54ae074fbfee	3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	security_headers	Referrer-Policy header missing	The response did not include a Referrer-Policy header.	info	\N	\N	https://demo.owasp-juice.shop/	\N	{}	Set a Referrer-Policy appropriate for your application's privacy requirements.	open	0.980	2026-10-09 21:09:06.448445+05:30	\N	2026-10-09 21:09:06.448445+05:30	2026-10-09 21:09:06.448445+05:30
\.


--
-- TOC entry 5247 (class 0 OID 33982)
-- Dependencies: 229
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, scan_id, scan_summary, security_findings, ai_analysis, intrusion_analysis, recommendations, created_at) FROM stdin;
\.


--
-- TOC entry 5245 (class 0 OID 33961)
-- Dependencies: 227
-- Data for Name: risk_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_scores (id, scan_id, severity_score, ai_confidence, impact_score, final_score, priority, created_at) FROM stdin;
\.


--
-- TOC entry 5256 (class 0 OID 34943)
-- Dependencies: 239
-- Data for Name: scan_endpoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_endpoints (id, scan_id, url, http_method, endpoint_type, depth, status_code, content_type, discovered_from, crawl_status, error_message, discovered_at, crawled_at) FROM stdin;
\.


--
-- TOC entry 5249 (class 0 OID 34002)
-- Dependencies: 231
-- Data for Name: scan_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_results (id, scan_id, result_type, title, description, raw_data, created_at) FROM stdin;
1	1	string	string	string	string	2026-08-25 16:50:01.470444
2	1	string	string	string	string	2026-08-25 16:55:55.549205
\.


--
-- TOC entry 5251 (class 0 OID 34502)
-- Dependencies: 233
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scans (id, user_id, target_url, scan_type, status, started_at, completed_at, error_message, findings_count, critical_count, high_count, scan_config, created_at, updated_at, spider, passive, active, scope_type, authorization_confirmed, crawl_depth, max_pages, request_delay_ms, javascript_crawling, follow_redirects, security_checks, excluded_paths, authentication_type, pages_discovered, requests_analyzed, endpoints_found) FROM stdin;
2d447ca9-3046-4ba0-b3da-139c94c9b888	f747336e-23e4-45fc-8236-0c405c66d66a	https://demo.example.test	active	completed	2026-10-03 19:37:34.24247+05:30	2026-10-03 19:39:34.24247+05:30	\N	1	0	1	{"depth": 2, "ai_classification": true}	2026-10-03 19:42:34.24247+05:30	2026-10-03 19:42:34.24247+05:30	t	t	f	single_url	f	5	500	100	t	t	["security_headers"]	[]	none	0	0	0
4d221de8-9285-4921-bd85-9f1a9f9c6376	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://thephotopunditz.com/	standard	queued	\N	\N	\N	0	0	0	{"scope": {"type": "domain", "excluded_paths": []}, "crawler": {"depth": 5, "delay_ms": 100, "max_pages": 500, "javascript": true, "follow_redirects": true}, "advanced": {"user_agent": "", "custom_headers": {}, "max_concurrent_requests": 5, "request_timeout_seconds": 30}, "security_checks": ["sql_injection", "xss", "csrf", "security_headers"]}	2026-10-03 20:13:23.000249+05:30	2026-10-03 20:13:23.000249+05:30	t	t	f	domain	f	5	500	100	t	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	0	0	0
25ea9f30-9c0d-4e14-8aba-ed11c26d282d	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://terminalonestudio.com/	standard	completed	2026-10-09 20:30:00.942413+05:30	2026-10-09 20:30:08.356682+05:30	\N	57	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 500, "scan_type": "standard", "scope_type": "single_url", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 100, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 30}	2026-10-09 20:30:00.931928+05:30	2026-10-09 20:30:08.356682+05:30	t	t	f	single_url	f	5	500	100	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	19	19	19
e3a30550-b40d-421e-852b-bcf67df007c2	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://thephotopunditz.com/	standard	completed	2026-10-09 20:08:41.846595+05:30	2026-10-09 20:08:50.050919+05:30	\N	108	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 500, "scan_type": "standard", "scope_type": "single_url", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 100, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 30}	2026-10-09 20:08:41.824659+05:30	2026-10-09 20:08:50.050919+05:30	t	t	f	single_url	f	5	500	100	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	53	53	53
3cbd0dee-5ac9-4d21-8bc3-3c980ae6d614	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://demo.owasp-juice.shop/	standard	completed	2026-10-09 21:09:01.916524+05:30	2026-10-09 21:09:06.448989+05:30	\N	4	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 500, "scan_type": "standard", "scope_type": "domain", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 100, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 30}	2026-10-09 21:09:01.907871+05:30	2026-10-09 21:09:06.448989+05:30	t	t	f	domain	f	5	500	100	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	1	1	1
aab39262-df1c-4568-9119-03cd43ef3b6e	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://thephotopunditz.com/	standard	completed	2026-10-09 20:23:07.336038+05:30	2026-10-09 20:23:15.274219+05:30	\N	108	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 500, "scan_type": "standard", "scope_type": "single_url", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 100, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 30}	2026-10-09 20:23:07.326719+05:30	2026-10-09 20:23:15.274219+05:30	t	t	f	single_url	f	5	500	100	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	53	53	53
\.


--
-- TOC entry 5239 (class 0 OID 33887)
-- Dependencies: 221
-- Data for Name: traffic_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.traffic_logs (id, source_ip, method, endpoint, status_code, user_agent, classification, confidence, created_at, scan_id) FROM stdin;
\.


--
-- TOC entry 5250 (class 0 OID 34481)
-- Dependencies: 232
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, full_name, role, is_active, last_login_at, created_at, updated_at) FROM stdin;
f747336e-23e4-45fc-8236-0c405c66d66a	analyst@example.test	$2b$12$EfwMs.au00Ftz93W7VpylelmWwuE.MrQN5T637hp5zVZ8jmczoKVi	Demo Security Analyst	analyst	t	2026-10-03 19:44:07.682591+05:30	2026-10-03 19:42:34.24247+05:30	2026-10-03 19:56:46.80992+05:30
525c3ae7-38c3-437b-b1c4-4aca10151a2a	sayali@gmail.com	$2b$12$XKRKUkm89Z2s8ADbKOLN/.SRVOSxg7mj455.qsoROqSUQZSS1b8Um	\N	analyst	t	\N	2026-10-09 21:11:09.277303+05:30	2026-10-09 21:11:09.277303+05:30
010752b0-dc79-4ad4-8293-6f4f7da62c57	mangeshbandre2307@gmail.com	$2b$12$rlJMCOczWVmXbpFeMQx5suEav7NxyBdD8PesU4rJot7/0R81LLJBm	Mangesh Bandre	analyst	t	2026-10-09 22:18:34.797025+05:30	2026-10-03 19:44:34.440962+05:30	2026-10-09 22:18:34.797025+05:30
\.


--
-- TOC entry 5241 (class 0 OID 33920)
-- Dependencies: 223
-- Data for Name: vulnerabilities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vulnerabilities (id, scan_id, type, severity, confidence, description, recommendation, status, created_at) FROM stdin;
1	1	string	string	0	string	string	open	2026-08-25 16:54:55.908134
2	1	string	string	0	string	string	open	2026-08-25 16:56:23.641013
\.


--
-- TOC entry 5274 (class 0 OID 0)
-- Dependencies: 235
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 9, true);


--
-- TOC entry 5275 (class 0 OID 0)
-- Dependencies: 224
-- Name: ai_predictions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ai_predictions_id_seq', 1, false);


--
-- TOC entry 5276 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 1, false);


--
-- TOC entry 5277 (class 0 OID 0)
-- Dependencies: 226
-- Name: risk_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.risk_scores_id_seq', 1, false);


--
-- TOC entry 5278 (class 0 OID 0)
-- Dependencies: 238
-- Name: scan_endpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_endpoints_id_seq', 1, false);


--
-- TOC entry 5279 (class 0 OID 0)
-- Dependencies: 230
-- Name: scan_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_results_id_seq', 2, true);


--
-- TOC entry 5280 (class 0 OID 0)
-- Dependencies: 220
-- Name: traffic_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.traffic_logs_id_seq', 1, false);


--
-- TOC entry 5281 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vulnerabilities_id_seq', 2, true);


--
-- TOC entry 5070 (class 2606 OID 34593)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5042 (class 2606 OID 33953)
-- Name: ai_predictions ai_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions
    ADD CONSTRAINT ai_predictions_pkey PRIMARY KEY (id);


--
-- TOC entry 5065 (class 2606 OID 34567)
-- Name: findings findings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_pkey PRIMARY KEY (id);


--
-- TOC entry 5049 (class 2606 OID 33992)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 5051 (class 2606 OID 33994)
-- Name: reports reports_scan_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_scan_id_key UNIQUE (scan_id);


--
-- TOC entry 5046 (class 2606 OID 33974)
-- Name: risk_scores risk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores
    ADD CONSTRAINT risk_scores_pkey PRIMARY KEY (id);


--
-- TOC entry 5078 (class 2606 OID 34965)
-- Name: scan_endpoints scan_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_pkey PRIMARY KEY (id);


--
-- TOC entry 5080 (class 2606 OID 34967)
-- Name: scan_endpoints scan_endpoints_scan_id_url_http_method_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_url_http_method_key UNIQUE (scan_id, url, http_method);


--
-- TOC entry 5055 (class 2606 OID 34014)
-- Name: scan_results scan_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results
    ADD CONSTRAINT scan_results_pkey PRIMARY KEY (id);


--
-- TOC entry 5063 (class 2606 OID 34533)
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- TOC entry 5037 (class 2606 OID 33897)
-- Name: traffic_logs traffic_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5058 (class 2606 OID 34500)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5040 (class 2606 OID 33933)
-- Name: vulnerabilities vulnerabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);


--
-- TOC entry 5071 (class 1259 OID 34604)
-- Name: idx_activity_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_created_at ON public.activity_logs USING btree (created_at DESC);


--
-- TOC entry 5072 (class 1259 OID 34606)
-- Name: idx_activity_logs_scan_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_scan_created_at ON public.activity_logs USING btree (scan_id, created_at DESC) WHERE (scan_id IS NOT NULL);


--
-- TOC entry 5073 (class 1259 OID 34607)
-- Name: idx_activity_logs_security_events; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_security_events ON public.activity_logs USING btree (created_at DESC) WHERE (level = ANY (ARRAY['warning'::public.log_level, 'error'::public.log_level, 'security'::public.log_level]));


--
-- TOC entry 5074 (class 1259 OID 34605)
-- Name: idx_activity_logs_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user_created_at ON public.activity_logs USING btree (user_id, created_at DESC) WHERE (user_id IS NOT NULL);


--
-- TOC entry 5066 (class 1259 OID 34575)
-- Name: idx_findings_cwe_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_cwe_id ON public.findings USING btree (cwe_id) WHERE (cwe_id IS NOT NULL);


--
-- TOC entry 5067 (class 1259 OID 34573)
-- Name: idx_findings_scan_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_scan_severity ON public.findings USING btree (scan_id, severity);


--
-- TOC entry 5068 (class 1259 OID 34574)
-- Name: idx_findings_status_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_status_severity ON public.findings USING btree (status, severity);


--
-- TOC entry 5075 (class 1259 OID 34973)
-- Name: idx_scan_endpoints_scan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_scan ON public.scan_endpoints USING btree (scan_id);


--
-- TOC entry 5076 (class 1259 OID 34974)
-- Name: idx_scan_endpoints_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_status ON public.scan_endpoints USING btree (scan_id, crawl_status);


--
-- TOC entry 5059 (class 1259 OID 34778)
-- Name: idx_scans_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_status_created_at ON public.scans USING btree (status, created_at DESC);


--
-- TOC entry 5060 (class 1259 OID 34539)
-- Name: idx_scans_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_created_at ON public.scans USING btree (user_id, created_at DESC);


--
-- TOC entry 5061 (class 1259 OID 34826)
-- Name: idx_scans_user_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_status_created_at ON public.scans USING btree (user_id, status, created_at DESC);


--
-- TOC entry 5033 (class 1259 OID 34981)
-- Name: idx_traffic_logs_id_desc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_id_desc ON public.traffic_logs USING btree (id DESC);


--
-- TOC entry 5034 (class 1259 OID 34980)
-- Name: idx_traffic_logs_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_scan_id ON public.traffic_logs USING btree (scan_id);


--
-- TOC entry 5043 (class 1259 OID 33959)
-- Name: ix_ai_predictions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ai_predictions_id ON public.ai_predictions USING btree (id);


--
-- TOC entry 5047 (class 1259 OID 34000)
-- Name: ix_reports_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reports_id ON public.reports USING btree (id);


--
-- TOC entry 5044 (class 1259 OID 33980)
-- Name: ix_risk_scores_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_risk_scores_id ON public.risk_scores USING btree (id);


--
-- TOC entry 5052 (class 1259 OID 34021)
-- Name: ix_scan_results_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_id ON public.scan_results USING btree (id);


--
-- TOC entry 5053 (class 1259 OID 34020)
-- Name: ix_scan_results_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_scan_id ON public.scan_results USING btree (scan_id);


--
-- TOC entry 5035 (class 1259 OID 33898)
-- Name: ix_traffic_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_traffic_logs_id ON public.traffic_logs USING btree (id);


--
-- TOC entry 5038 (class 1259 OID 33939)
-- Name: ix_vulnerabilities_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vulnerabilities_id ON public.vulnerabilities USING btree (id);


--
-- TOC entry 5056 (class 1259 OID 34501)
-- Name: uq_users_email_lower; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_email_lower ON public.users USING btree (lower((email)::text));


--
-- TOC entry 5237 (class 2618 OID 34830)
-- Name: scan_risk_summary _RETURN; Type: RULE; Schema: public; Owner: postgres
--

CREATE OR REPLACE VIEW public.scan_risk_summary AS
 SELECT s.id AS scan_id,
    s.user_id,
    s.target_url,
    s.status AS scan_status,
    s.created_at,
    count(f.id) AS total_findings,
    count(*) FILTER (WHERE (f.severity = 'critical'::public.risk_severity)) AS critical_findings,
    count(*) FILTER (WHERE (f.severity = 'high'::public.risk_severity)) AS high_findings,
    count(*) FILTER (WHERE (f.severity = 'medium'::public.risk_severity)) AS medium_findings,
    COALESCE(max(f.cvss_score), (0)::numeric) AS highest_cvss_score
   FROM (public.scans s
     LEFT JOIN public.findings f ON ((f.scan_id = s.id)))
  GROUP BY s.id;


--
-- TOC entry 5089 (class 2620 OID 34611)
-- Name: findings findings_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER findings_set_updated_at BEFORE UPDATE ON public.findings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5088 (class 2620 OID 34610)
-- Name: scans scans_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER scans_set_updated_at BEFORE UPDATE ON public.scans FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5087 (class 2620 OID 34609)
-- Name: users users_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5084 (class 2606 OID 34599)
-- Name: activity_logs activity_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE SET NULL;


--
-- TOC entry 5085 (class 2606 OID 34594)
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5083 (class 2606 OID 34568)
-- Name: findings findings_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5086 (class 2606 OID 34968)
-- Name: scan_endpoints scan_endpoints_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5082 (class 2606 OID 34534)
-- Name: scans scans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5081 (class 2606 OID 34975)
-- Name: traffic_logs traffic_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


-- Completed on 2026-10-09 22:48:07

--
-- PostgreSQL database dump complete
--

\unrestrict wilZhkpVewNuAmf7wA3aRDZmcVnBIer3k1Oa5hmTY2Ojc5jYg5sJANKfoCvrOKz


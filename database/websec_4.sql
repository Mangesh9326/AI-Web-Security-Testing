--
-- PostgreSQL database dump
--

\restrict ZCtles2t1XvV4tmLl3mgkemqBBgbXXtegu5q6yCj4x08zKI0wgdbHut9gphjZpN

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-10 00:56:29

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
-- TOC entry 5320 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 967 (class 1247 OID 35048)
-- Name: alert_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.alert_status AS ENUM (
    'new',
    'investigating',
    'confirmed',
    'false_positive',
    'resolved'
);


ALTER TYPE public.alert_status OWNER TO postgres;

--
-- TOC entry 943 (class 1247 OID 34458)
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
-- TOC entry 946 (class 1247 OID 34470)
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
-- TOC entry 940 (class 1247 OID 34446)
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
-- TOC entry 934 (class 1247 OID 34426)
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
-- TOC entry 937 (class 1247 OID 34438)
-- Name: scan_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scan_type AS ENUM (
    'passive',
    'active',
    'authenticated'
);


ALTER TYPE public.scan_type OWNER TO postgres;

--
-- TOC entry 931 (class 1247 OID 34418)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'analyst',
    'viewer'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 280 (class 1255 OID 34608)
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
-- TOC entry 5321 (class 0 OID 0)
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
-- TOC entry 5322 (class 0 OID 0)
-- Dependencies: 224
-- Name: ai_predictions_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.ai_predictions_id_seq OWNED BY public.ai_predictions.id;


--
-- TOC entry 242 (class 1259 OID 35142)
-- Name: alert_audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    alert_id uuid NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    previous_value text,
    new_value text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.alert_audit_logs OWNER TO postgres;

--
-- TOC entry 241 (class 1259 OID 35116)
-- Name: alert_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alert_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    alert_id uuid NOT NULL,
    author_id uuid NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT alert_notes_length_check CHECK (((length(btrim(note)) > 0) AND (length(note) <= 2000)))
);


ALTER TABLE public.alert_notes OWNER TO postgres;

--
-- TOC entry 240 (class 1259 OID 35059)
-- Name: alerts; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.alerts (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    scan_id uuid NOT NULL,
    traffic_log_id integer,
    correlation_key character varying(255) NOT NULL,
    rule_id character varying(100) NOT NULL,
    classification character varying(100) NOT NULL,
    severity character varying(20) NOT NULL,
    confidence double precision NOT NULL,
    source_ip character varying(100),
    target_url text,
    endpoint character varying(500) NOT NULL,
    http_method character varying(20) NOT NULL,
    status public.alert_status DEFAULT 'new'::public.alert_status NOT NULL,
    occurrence_count integer DEFAULT 1 NOT NULL,
    description text NOT NULL,
    evidence jsonb DEFAULT '{}'::jsonb NOT NULL,
    analyst_notes text,
    first_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_to uuid,
    CONSTRAINT alerts_confidence_range CHECK (((confidence >= (0.0)::double precision) AND (confidence <= (1.0)::double precision))),
    CONSTRAINT alerts_occurrence_count_positive CHECK ((occurrence_count >= 1))
);


ALTER TABLE public.alerts OWNER TO postgres;

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
-- TOC entry 5323 (class 0 OID 0)
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
-- TOC entry 5324 (class 0 OID 0)
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
-- TOC entry 5325 (class 0 OID 0)
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
-- TOC entry 5326 (class 0 OID 0)
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
-- TOC entry 5327 (class 0 OID 0)
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
-- TOC entry 5328 (class 0 OID 0)
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
    scan_id uuid,
    event_type character varying(50) DEFAULT 'http_request'::character varying NOT NULL,
    severity character varying(50),
    evidence jsonb DEFAULT '{}'::jsonb NOT NULL
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
-- TOC entry 5329 (class 0 OID 0)
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
-- TOC entry 5330 (class 0 OID 0)
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
-- TOC entry 5331 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vulnerabilities_id_seq OWNED BY public.vulnerabilities.id;


--
-- TOC entry 4983 (class 2604 OID 33944)
-- Name: ai_predictions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions ALTER COLUMN id SET DEFAULT nextval('public.ai_predictions_id_seq'::regclass);


--
-- TOC entry 4985 (class 2604 OID 33985)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 4984 (class 2604 OID 33964)
-- Name: risk_scores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores ALTER COLUMN id SET DEFAULT nextval('public.risk_scores_id_seq'::regclass);


--
-- TOC entry 5026 (class 2604 OID 34946)
-- Name: scan_endpoints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints ALTER COLUMN id SET DEFAULT nextval('public.scan_endpoints_id_seq'::regclass);


--
-- TOC entry 4986 (class 2604 OID 34005)
-- Name: scan_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results ALTER COLUMN id SET DEFAULT nextval('public.scan_results_id_seq'::regclass);


--
-- TOC entry 4979 (class 2604 OID 33890)
-- Name: traffic_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs ALTER COLUMN id SET DEFAULT nextval('public.traffic_logs_id_seq'::regclass);


--
-- TOC entry 4982 (class 2604 OID 33923)
-- Name: vulnerabilities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.vulnerabilities_id_seq'::regclass);


--
-- TOC entry 5309 (class 0 OID 34577)
-- Dependencies: 236
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_id, scan_id, level, action, message, ip_address, user_agent, details, created_at) FROM stdin;
1	f747336e-23e4-45fc-8236-0c405c66d66a	\N	info	seed.created	Development seed data applied.	\N	\N	{"source": "backend/seed_data.py"}	2026-10-03 19:42:34.24247+05:30
7	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 57, "endpoints_found": 19, "pages_discovered": 19, "requests_analyzed": 19}	2026-10-09 20:30:08.357829+05:30
6	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-09 20:30:00.937002+05:30
3	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:08:50.058772+05:30
2	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:08:41.831554+05:30
9	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 4, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-09 21:09:06.450083+05:30
8	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://demo.owasp-juice.shop/"}	2026-10-09 21:09:01.910695+05:30
5	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "endpoints_found": 53, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:23:15.275866+05:30
4	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:23:07.330114+05:30
\.


--
-- TOC entry 5298 (class 0 OID 33941)
-- Dependencies: 225
-- Data for Name: ai_predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_predictions (id, scan_id, input_type, prediction, confidence, model_name, created_at) FROM stdin;
\.


--
-- TOC entry 5314 (class 0 OID 35142)
-- Dependencies: 242
-- Data for Name: alert_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_audit_logs (id, alert_id, user_id, action, previous_value, new_value, metadata, created_at) FROM stdin;
\.


--
-- TOC entry 5313 (class 0 OID 35116)
-- Dependencies: 241
-- Data for Name: alert_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_notes (id, alert_id, author_id, note, created_at) FROM stdin;
\.


--
-- TOC entry 5312 (class 0 OID 35059)
-- Dependencies: 240
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, scan_id, traffic_log_id, correlation_key, rule_id, classification, severity, confidence, source_ip, target_url, endpoint, http_method, status, occurrence_count, description, evidence, analyst_notes, first_seen_at, last_seen_at, created_at, updated_at, assigned_to) FROM stdin;
\.


--
-- TOC entry 5307 (class 0 OID 34541)
-- Dependencies: 234
-- Data for Name: findings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.findings (id, scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, status, ai_confidence, detected_at, resolved_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5302 (class 0 OID 33982)
-- Dependencies: 229
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, scan_id, scan_summary, security_findings, ai_analysis, intrusion_analysis, recommendations, created_at) FROM stdin;
\.


--
-- TOC entry 5300 (class 0 OID 33961)
-- Dependencies: 227
-- Data for Name: risk_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_scores (id, scan_id, severity_score, ai_confidence, impact_score, final_score, priority, created_at) FROM stdin;
\.


--
-- TOC entry 5311 (class 0 OID 34943)
-- Dependencies: 239
-- Data for Name: scan_endpoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_endpoints (id, scan_id, url, http_method, endpoint_type, depth, status_code, content_type, discovered_from, crawl_status, error_message, discovered_at, crawled_at) FROM stdin;
\.


--
-- TOC entry 5304 (class 0 OID 34002)
-- Dependencies: 231
-- Data for Name: scan_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_results (id, scan_id, result_type, title, description, raw_data, created_at) FROM stdin;
1	1	string	string	string	string	2026-08-25 16:50:01.470444
2	1	string	string	string	string	2026-08-25 16:55:55.549205
\.


--
-- TOC entry 5306 (class 0 OID 34502)
-- Dependencies: 233
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scans (id, user_id, target_url, scan_type, status, started_at, completed_at, error_message, findings_count, critical_count, high_count, scan_config, created_at, updated_at, spider, passive, active, scope_type, authorization_confirmed, crawl_depth, max_pages, request_delay_ms, javascript_crawling, follow_redirects, security_checks, excluded_paths, authentication_type, pages_discovered, requests_analyzed, endpoints_found) FROM stdin;
\.


--
-- TOC entry 5294 (class 0 OID 33887)
-- Dependencies: 221
-- Data for Name: traffic_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.traffic_logs (id, source_ip, method, endpoint, status_code, user_agent, classification, confidence, created_at, scan_id, event_type, severity, evidence) FROM stdin;
\.


--
-- TOC entry 5305 (class 0 OID 34481)
-- Dependencies: 232
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, full_name, role, is_active, last_login_at, created_at, updated_at) FROM stdin;
f747336e-23e4-45fc-8236-0c405c66d66a	analyst@example.test	$2b$12$EfwMs.au00Ftz93W7VpylelmWwuE.MrQN5T637hp5zVZ8jmczoKVi	Demo Security Analyst	analyst	t	2026-10-03 19:44:07.682591+05:30	2026-10-03 19:42:34.24247+05:30	2026-10-03 19:56:46.80992+05:30
525c3ae7-38c3-437b-b1c4-4aca10151a2a	sayali@gmail.com	$2b$12$XKRKUkm89Z2s8ADbKOLN/.SRVOSxg7mj455.qsoROqSUQZSS1b8Um	\N	analyst	t	\N	2026-10-09 21:11:09.277303+05:30	2026-10-09 21:11:09.277303+05:30
010752b0-dc79-4ad4-8293-6f4f7da62c57	mangeshbandre2307@gmail.com	$2b$12$rlJMCOczWVmXbpFeMQx5suEav7NxyBdD8PesU4rJot7/0R81LLJBm	Mangesh Bandre	analyst	t	2026-10-10 00:51:33.352729+05:30	2026-10-03 19:44:34.440962+05:30	2026-10-10 00:51:33.352729+05:30
\.


--
-- TOC entry 5296 (class 0 OID 33920)
-- Dependencies: 223
-- Data for Name: vulnerabilities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vulnerabilities (id, scan_id, type, severity, confidence, description, recommendation, status, created_at) FROM stdin;
1	1	string	string	0	string	string	open	2026-08-25 16:54:55.908134
2	1	string	string	0	string	string	open	2026-08-25 16:56:23.641013
\.


--
-- TOC entry 5332 (class 0 OID 0)
-- Dependencies: 235
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 9, true);


--
-- TOC entry 5333 (class 0 OID 0)
-- Dependencies: 224
-- Name: ai_predictions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ai_predictions_id_seq', 1, false);


--
-- TOC entry 5334 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 1, false);


--
-- TOC entry 5335 (class 0 OID 0)
-- Dependencies: 226
-- Name: risk_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.risk_scores_id_seq', 1, false);


--
-- TOC entry 5336 (class 0 OID 0)
-- Dependencies: 238
-- Name: scan_endpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_endpoints_id_seq', 1, false);


--
-- TOC entry 5337 (class 0 OID 0)
-- Dependencies: 230
-- Name: scan_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_results_id_seq', 2, true);


--
-- TOC entry 5338 (class 0 OID 0)
-- Dependencies: 220
-- Name: traffic_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.traffic_logs_id_seq', 1, false);


--
-- TOC entry 5339 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vulnerabilities_id_seq', 2, true);


--
-- TOC entry 5103 (class 2606 OID 34593)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5075 (class 2606 OID 33953)
-- Name: ai_predictions ai_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions
    ADD CONSTRAINT ai_predictions_pkey PRIMARY KEY (id);


--
-- TOC entry 5126 (class 2606 OID 35156)
-- Name: alert_audit_logs alert_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5123 (class 2606 OID 35130)
-- Name: alert_notes alert_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 5115 (class 2606 OID 35092)
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- TOC entry 5098 (class 2606 OID 34567)
-- Name: findings findings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_pkey PRIMARY KEY (id);


--
-- TOC entry 5082 (class 2606 OID 33992)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 5084 (class 2606 OID 33994)
-- Name: reports reports_scan_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_scan_id_key UNIQUE (scan_id);


--
-- TOC entry 5079 (class 2606 OID 33974)
-- Name: risk_scores risk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores
    ADD CONSTRAINT risk_scores_pkey PRIMARY KEY (id);


--
-- TOC entry 5111 (class 2606 OID 34965)
-- Name: scan_endpoints scan_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_pkey PRIMARY KEY (id);


--
-- TOC entry 5113 (class 2606 OID 34967)
-- Name: scan_endpoints scan_endpoints_scan_id_url_http_method_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_url_http_method_key UNIQUE (scan_id, url, http_method);


--
-- TOC entry 5088 (class 2606 OID 34014)
-- Name: scan_results scan_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results
    ADD CONSTRAINT scan_results_pkey PRIMARY KEY (id);


--
-- TOC entry 5096 (class 2606 OID 34533)
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- TOC entry 5070 (class 2606 OID 33897)
-- Name: traffic_logs traffic_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5091 (class 2606 OID 34500)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5073 (class 2606 OID 33933)
-- Name: vulnerabilities vulnerabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);


--
-- TOC entry 5104 (class 1259 OID 34604)
-- Name: idx_activity_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_created_at ON public.activity_logs USING btree (created_at DESC);


--
-- TOC entry 5105 (class 1259 OID 34606)
-- Name: idx_activity_logs_scan_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_scan_created_at ON public.activity_logs USING btree (scan_id, created_at DESC) WHERE (scan_id IS NOT NULL);


--
-- TOC entry 5106 (class 1259 OID 34607)
-- Name: idx_activity_logs_security_events; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_security_events ON public.activity_logs USING btree (created_at DESC) WHERE (level = ANY (ARRAY['warning'::public.log_level, 'error'::public.log_level, 'security'::public.log_level]));


--
-- TOC entry 5107 (class 1259 OID 34605)
-- Name: idx_activity_logs_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user_created_at ON public.activity_logs USING btree (user_id, created_at DESC) WHERE (user_id IS NOT NULL);


--
-- TOC entry 5127 (class 1259 OID 35167)
-- Name: idx_alert_audit_logs_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_audit_logs_alert_id ON public.alert_audit_logs USING btree (alert_id, created_at);


--
-- TOC entry 5124 (class 1259 OID 35141)
-- Name: idx_alert_notes_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_notes_alert_id ON public.alert_notes USING btree (alert_id, created_at);


--
-- TOC entry 5116 (class 1259 OID 35115)
-- Name: idx_alerts_assigned_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_assigned_to ON public.alerts USING btree (assigned_to);


--
-- TOC entry 5117 (class 1259 OID 35104)
-- Name: idx_alerts_correlation_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_correlation_key ON public.alerts USING btree (correlation_key);


--
-- TOC entry 5118 (class 1259 OID 35107)
-- Name: idx_alerts_last_seen_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_last_seen_at ON public.alerts USING btree (last_seen_at DESC);


--
-- TOC entry 5119 (class 1259 OID 35103)
-- Name: idx_alerts_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_scan_id ON public.alerts USING btree (scan_id);


--
-- TOC entry 5120 (class 1259 OID 35106)
-- Name: idx_alerts_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_severity ON public.alerts USING btree (severity);


--
-- TOC entry 5121 (class 1259 OID 35105)
-- Name: idx_alerts_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_status ON public.alerts USING btree (status);


--
-- TOC entry 5099 (class 1259 OID 34575)
-- Name: idx_findings_cwe_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_cwe_id ON public.findings USING btree (cwe_id) WHERE (cwe_id IS NOT NULL);


--
-- TOC entry 5100 (class 1259 OID 34573)
-- Name: idx_findings_scan_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_scan_severity ON public.findings USING btree (scan_id, severity);


--
-- TOC entry 5101 (class 1259 OID 34574)
-- Name: idx_findings_status_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_status_severity ON public.findings USING btree (status, severity);


--
-- TOC entry 5108 (class 1259 OID 34973)
-- Name: idx_scan_endpoints_scan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_scan ON public.scan_endpoints USING btree (scan_id);


--
-- TOC entry 5109 (class 1259 OID 34974)
-- Name: idx_scan_endpoints_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_status ON public.scan_endpoints USING btree (scan_id, crawl_status);


--
-- TOC entry 5092 (class 1259 OID 34778)
-- Name: idx_scans_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_status_created_at ON public.scans USING btree (status, created_at DESC);


--
-- TOC entry 5093 (class 1259 OID 34539)
-- Name: idx_scans_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_created_at ON public.scans USING btree (user_id, created_at DESC);


--
-- TOC entry 5094 (class 1259 OID 34826)
-- Name: idx_scans_user_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_status_created_at ON public.scans USING btree (user_id, status, created_at DESC);


--
-- TOC entry 5066 (class 1259 OID 34981)
-- Name: idx_traffic_logs_id_desc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_id_desc ON public.traffic_logs USING btree (id DESC);


--
-- TOC entry 5067 (class 1259 OID 34980)
-- Name: idx_traffic_logs_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_scan_id ON public.traffic_logs USING btree (scan_id);


--
-- TOC entry 5076 (class 1259 OID 33959)
-- Name: ix_ai_predictions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ai_predictions_id ON public.ai_predictions USING btree (id);


--
-- TOC entry 5080 (class 1259 OID 34000)
-- Name: ix_reports_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reports_id ON public.reports USING btree (id);


--
-- TOC entry 5077 (class 1259 OID 33980)
-- Name: ix_risk_scores_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_risk_scores_id ON public.risk_scores USING btree (id);


--
-- TOC entry 5085 (class 1259 OID 34021)
-- Name: ix_scan_results_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_id ON public.scan_results USING btree (id);


--
-- TOC entry 5086 (class 1259 OID 34020)
-- Name: ix_scan_results_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_scan_id ON public.scan_results USING btree (scan_id);


--
-- TOC entry 5068 (class 1259 OID 33898)
-- Name: ix_traffic_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_traffic_logs_id ON public.traffic_logs USING btree (id);


--
-- TOC entry 5071 (class 1259 OID 33939)
-- Name: ix_vulnerabilities_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vulnerabilities_id ON public.vulnerabilities USING btree (id);


--
-- TOC entry 5089 (class 1259 OID 34501)
-- Name: uq_users_email_lower; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_email_lower ON public.users USING btree (lower((email)::text));


--
-- TOC entry 5292 (class 2618 OID 34830)
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
-- TOC entry 5144 (class 2620 OID 35108)
-- Name: alerts alerts_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER alerts_set_updated_at BEFORE UPDATE ON public.alerts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5143 (class 2620 OID 34611)
-- Name: findings findings_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER findings_set_updated_at BEFORE UPDATE ON public.findings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5142 (class 2620 OID 34610)
-- Name: scans scans_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER scans_set_updated_at BEFORE UPDATE ON public.scans FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5141 (class 2620 OID 34609)
-- Name: users users_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5131 (class 2606 OID 34599)
-- Name: activity_logs activity_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE SET NULL;


--
-- TOC entry 5132 (class 2606 OID 34594)
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5139 (class 2606 OID 35157)
-- Name: alert_audit_logs alert_audit_logs_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- TOC entry 5140 (class 2606 OID 35162)
-- Name: alert_audit_logs alert_audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5137 (class 2606 OID 35131)
-- Name: alert_notes alert_notes_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- TOC entry 5138 (class 2606 OID 35136)
-- Name: alert_notes alert_notes_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5134 (class 2606 OID 35110)
-- Name: alerts alerts_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5135 (class 2606 OID 35093)
-- Name: alerts alerts_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5136 (class 2606 OID 35098)
-- Name: alerts alerts_traffic_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_traffic_log_id_fkey FOREIGN KEY (traffic_log_id) REFERENCES public.traffic_logs(id) ON DELETE SET NULL;


--
-- TOC entry 5130 (class 2606 OID 34568)
-- Name: findings findings_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5133 (class 2606 OID 34968)
-- Name: scan_endpoints scan_endpoints_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5129 (class 2606 OID 34534)
-- Name: scans scans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5128 (class 2606 OID 34975)
-- Name: traffic_logs traffic_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


-- Completed on 2026-10-10 00:56:30

--
-- PostgreSQL database dump complete
--

\unrestrict ZCtles2t1XvV4tmLl3mgkemqBBgbXXtegu5q6yCj4x08zKI0wgdbHut9gphjZpN


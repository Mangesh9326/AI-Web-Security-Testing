--
-- PostgreSQL database dump
--

\restrict dGTG5CmnT9WIg3qOZ9CsBDPs2t0UHnbHSXq0aiRUc9wPFKY29JvsszW9fjFOmKS

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-10 05:07:01

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
-- TOC entry 5349 (class 0 OID 0)
-- Dependencies: 2
-- Name: EXTENSION pgcrypto; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION pgcrypto IS 'cryptographic functions';


--
-- TOC entry 969 (class 1247 OID 35048)
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
-- TOC entry 945 (class 1247 OID 34458)
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
-- TOC entry 948 (class 1247 OID 34470)
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
-- TOC entry 942 (class 1247 OID 34446)
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
-- TOC entry 936 (class 1247 OID 34426)
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
-- TOC entry 939 (class 1247 OID 34438)
-- Name: scan_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.scan_type AS ENUM (
    'passive',
    'active',
    'authenticated'
);


ALTER TYPE public.scan_type OWNER TO postgres;

--
-- TOC entry 933 (class 1247 OID 34418)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'analyst',
    'viewer'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- TOC entry 282 (class 1255 OID 34608)
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
-- TOC entry 5350 (class 0 OID 0)
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
-- TOC entry 5351 (class 0 OID 0)
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
-- TOC entry 244 (class 1259 OID 35202)
-- Name: finding_audit_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finding_audit_logs (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    finding_id uuid NOT NULL,
    user_id uuid,
    action character varying(100) NOT NULL,
    previous_value text,
    new_value text,
    metadata jsonb DEFAULT '{}'::jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.finding_audit_logs OWNER TO postgres;

--
-- TOC entry 243 (class 1259 OID 35176)
-- Name: finding_notes; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.finding_notes (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    finding_id uuid NOT NULL,
    author_id uuid NOT NULL,
    note text NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT finding_notes_length_check CHECK (((length(btrim(note)) > 0) AND (length(note) <= 2000)))
);


ALTER TABLE public.finding_notes OWNER TO postgres;

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
    fingerprint character varying(255),
    last_seen_at timestamp with time zone DEFAULT now() NOT NULL,
    assigned_to uuid,
    CONSTRAINT findings_ai_confidence_check CHECK (((ai_confidence >= 0.000) AND (ai_confidence <= 1.000))),
    CONSTRAINT findings_cvss_score_check CHECK (((cvss_score >= 0.0) AND (cvss_score <= 10.0))),
    CONSTRAINT findings_resolved_at_valid CHECK (((resolved_at IS NULL) OR (resolved_at >= detected_at))),
    CONSTRAINT findings_title_not_blank CHECK ((length(btrim((title)::text)) > 0))
);


ALTER TABLE public.findings OWNER TO postgres;

--
-- TOC entry 5352 (class 0 OID 0)
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
-- TOC entry 5353 (class 0 OID 0)
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
-- TOC entry 5354 (class 0 OID 0)
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
-- TOC entry 5355 (class 0 OID 0)
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
-- TOC entry 5356 (class 0 OID 0)
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
-- TOC entry 5357 (class 0 OID 0)
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
-- TOC entry 5358 (class 0 OID 0)
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
-- TOC entry 5359 (class 0 OID 0)
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
-- TOC entry 5360 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vulnerabilities_id_seq OWNED BY public.vulnerabilities.id;


--
-- TOC entry 4991 (class 2604 OID 33944)
-- Name: ai_predictions id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions ALTER COLUMN id SET DEFAULT nextval('public.ai_predictions_id_seq'::regclass);


--
-- TOC entry 4993 (class 2604 OID 33985)
-- Name: reports id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports ALTER COLUMN id SET DEFAULT nextval('public.reports_id_seq'::regclass);


--
-- TOC entry 4992 (class 2604 OID 33964)
-- Name: risk_scores id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores ALTER COLUMN id SET DEFAULT nextval('public.risk_scores_id_seq'::regclass);


--
-- TOC entry 5035 (class 2604 OID 34946)
-- Name: scan_endpoints id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints ALTER COLUMN id SET DEFAULT nextval('public.scan_endpoints_id_seq'::regclass);


--
-- TOC entry 4994 (class 2604 OID 34005)
-- Name: scan_results id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results ALTER COLUMN id SET DEFAULT nextval('public.scan_results_id_seq'::regclass);


--
-- TOC entry 4987 (class 2604 OID 33890)
-- Name: traffic_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs ALTER COLUMN id SET DEFAULT nextval('public.traffic_logs_id_seq'::regclass);


--
-- TOC entry 4990 (class 2604 OID 33923)
-- Name: vulnerabilities id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities ALTER COLUMN id SET DEFAULT nextval('public.vulnerabilities_id_seq'::regclass);


--
-- TOC entry 5336 (class 0 OID 34577)
-- Dependencies: 236
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_id, scan_id, level, action, message, ip_address, user_agent, details, created_at) FROM stdin;
455	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 04:26:38.043481+05:30
470	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 04:26:43.492536+05:30
485	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 04:26:49.200558+05:30
500	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 04:26:54.837304+05:30
516	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/taj--pan-india", "reason": "42P08"}	2026-10-10 04:27:17.886256+05:30
531	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/404", "reason": "42P08"}	2026-10-10 04:27:23.11019+05:30
1	f747336e-23e4-45fc-8236-0c405c66d66a	\N	info	seed.created	Development seed data applied.	\N	\N	{"source": "backend/seed_data.py"}	2026-10-03 19:42:34.24247+05:30
7	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 57, "endpoints_found": 19, "pages_discovered": 19, "requests_analyzed": 19}	2026-10-09 20:30:08.357829+05:30
6	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-09 20:30:00.937002+05:30
3	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:08:50.058772+05:30
2	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:08:41.831554+05:30
9	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 4, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-09 21:09:06.450083+05:30
8	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://demo.owasp-juice.shop/"}	2026-10-09 21:09:01.910695+05:30
5	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 108, "endpoints_found": 53, "pages_discovered": 53, "requests_analyzed": 53}	2026-10-09 20:23:15.275866+05:30
4	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-09 20:23:07.330114+05:30
12	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 0, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 01:16:12.660287+05:30
11	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 01:16:12.650411+05:30
10	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 01:16:12.451477+05:30
15	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 0, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 01:16:32.003459+05:30
14	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 01:16:31.990557+05:30
13	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 01:16:31.810118+05:30
18	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 0, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 01:23:50.491688+05:30
17	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 01:23:50.479585+05:30
16	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 01:23:50.344155+05:30
21	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 0, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 01:25:31.392392+05:30
20	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 01:25:31.389537+05:30
19	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 01:25:31.253922+05:30
22	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 02:08:02.503514+05:30
23	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 02:08:02.708802+05:30
24	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 02:08:02.722776+05:30
25	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-10 02:12:52.286451+05:30
456	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 04:26:38.42138+05:30
471	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 04:26:43.873416+05:30
486	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:26:49.800028+05:30
501	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 04:26:55.180681+05:30
517	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/coorg", "reason": "42P08"}	2026-10-10 04:27:18.220477+05:30
532	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/", "reason": "42P08"}	2026-10-10 04:27:23.453316+05:30
26	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/", "reason": "error"}	2026-10-10 02:12:52.432873+05:30
457	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 04:26:38.759594+05:30
472	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 04:26:44.245686+05:30
487	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:26:50.155504+05:30
502	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 04:26:55.527022+05:30
518	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/taj-patna", "reason": "42P08"}	2026-10-10 04:27:18.562026+05:30
533	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/projects", "reason": "42P08"}	2026-10-10 04:27:23.792105+05:30
458	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 04:26:39.130919+05:30
473	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 04:26:44.636664+05:30
488	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:26:50.533537+05:30
503	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:26:55.886406+05:30
519	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/orient-express", "reason": "42P08"}	2026-10-10 04:27:18.904426+05:30
534	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/video", "reason": "42P08"}	2026-10-10 04:27:24.136005+05:30
459	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 04:26:39.487999+05:30
474	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 04:26:45.014956+05:30
489	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 04:26:50.905865+05:30
504	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 04:26:56.225878+05:30
520	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction", "reason": "42P08"}	2026-10-10 04:27:19.246092+05:30
535	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/about", "reason": "42P08"}	2026-10-10 04:27:24.477887+05:30
460	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 04:26:39.842664+05:30
475	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 04:26:45.4971+05:30
490	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:26:51.27628+05:30
505	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 04:26:56.589843+05:30
521	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/conrad-bengaluru", "reason": "42P08"}	2026-10-10 04:27:19.695796+05:30
536	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/contact", "reason": "42P08"}	2026-10-10 04:27:24.81964+05:30
461	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 04:26:40.201957+05:30
476	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 04:26:45.886938+05:30
491	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 04:26:51.631258+05:30
506	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:26:56.971917+05:30
522	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/loya", "reason": "42P08"}	2026-10-10 04:27:20.012055+05:30
537	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/carrer", "reason": "42P08"}	2026-10-10 04:27:25.160015+05:30
538	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 81, "endpoints_found": 28, "pages_discovered": 28, "requests_analyzed": 28}	2026-10-10 04:27:25.279009+05:30
462	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 04:26:40.656106+05:30
477	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 04:26:46.25465+05:30
492	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 04:26:51.985979+05:30
507	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:26:57.348464+05:30
508	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 04:26:57.497933+05:30
523	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/spicy-duck", "reason": "42P08"}	2026-10-10 04:27:20.359636+05:30
463	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 04:26:40.988142+05:30
478	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 04:26:46.650472+05:30
493	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 04:26:52.342411+05:30
509	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-10 04:27:15.732793+05:30
524	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions", "reason": "42P08"}	2026-10-10 04:27:20.705338+05:30
464	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 04:26:41.316325+05:30
479	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 04:26:47.027744+05:30
494	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 04:26:52.7065+05:30
510	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/", "reason": "42P08"}	2026-10-10 04:27:15.838769+05:30
525	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/the-blue-bar", "reason": "42P08"}	2026-10-10 04:27:21.0457+05:30
465	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 04:26:41.676562+05:30
480	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 04:26:47.388832+05:30
495	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 04:26:53.063303+05:30
511	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects", "reason": "42P08"}	2026-10-10 04:27:16.179289+05:30
526	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/gateway-bekal", "reason": "42P08"}	2026-10-10 04:27:21.391592+05:30
466	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 04:26:42.031208+05:30
481	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:26:47.732878+05:30
496	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 04:26:53.419003+05:30
512	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/video", "reason": "42P08"}	2026-10-10 04:27:16.511301+05:30
527	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/zhen-zhu", "reason": "42P08"}	2026-10-10 04:27:21.733624+05:30
467	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 04:26:42.375822+05:30
482	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 04:26:48.087035+05:30
497	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 04:26:53.784644+05:30
513	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/about", "reason": "42P08"}	2026-10-10 04:27:16.858096+05:30
528	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/capital-kitchen", "reason": "42P08"}	2026-10-10 04:27:22.078693+05:30
468	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 04:26:42.747717+05:30
483	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 04:26:48.451686+05:30
498	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 04:26:54.120798+05:30
514	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/contact", "reason": "42P08"}	2026-10-10 04:27:17.200564+05:30
529	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/the-tea-lounge", "reason": "42P08"}	2026-10-10 04:27:22.423292+05:30
100	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "http://localhost:3000/"}	2026-10-10 03:15:21.930228+05:30
101	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/", "reason": "42P08"}	2026-10-10 03:15:22.089599+05:30
102	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/assets/public/favicon_js.ico", "reason": "42P08"}	2026-10-10 03:15:22.39923+05:30
103	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/styles.css", "reason": "42P08"}	2026-10-10 03:15:22.733245+05:30
104	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/rolldown-runtime-BoHGiXSq.js", "reason": "42P08"}	2026-10-10 03:15:23.091459+05:30
105	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/chunk-DBPdFzgj.js", "reason": "42P08"}	2026-10-10 03:15:23.45476+05:30
106	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/chunk-CVpW03Vy.js", "reason": "42P08"}	2026-10-10 03:15:23.877138+05:30
107	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/chunk-BKBqgHvK.js", "reason": "42P08"}	2026-10-10 03:15:24.240058+05:30
108	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/polyfills.js", "reason": "42P08"}	2026-10-10 03:15:24.593227+05:30
109	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/scripts.js", "reason": "42P08"}	2026-10-10 03:15:24.960628+05:30
110	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "http://localhost:3000/main.js", "reason": "42P08"}	2026-10-10 03:15:25.428884+05:30
111	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 20, "endpoints_found": 10, "pages_discovered": 10, "requests_analyzed": 10}	2026-10-10 03:15:25.487261+05:30
112	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "passive", "target_url": "https://terminalonestudio.com/"}	2026-10-10 03:16:05.781757+05:30
113	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/", "reason": "42P08"}	2026-10-10 03:16:05.895496+05:30
114	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects", "reason": "42P08"}	2026-10-10 03:16:06.25209+05:30
115	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/video", "reason": "42P08"}	2026-10-10 03:16:06.595861+05:30
116	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/about", "reason": "42P08"}	2026-10-10 03:16:06.947656+05:30
117	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/contact", "reason": "42P08"}	2026-10-10 03:16:07.406948+05:30
118	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/carrer", "reason": "42P08"}	2026-10-10 03:16:07.744933+05:30
119	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/taj--pan-india", "reason": "42P08"}	2026-10-10 03:16:08.100826+05:30
120	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/coorg", "reason": "42P08"}	2026-10-10 03:16:08.45092+05:30
121	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/taj-patna", "reason": "42P08"}	2026-10-10 03:16:08.796439+05:30
122	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/orient-express", "reason": "42P08"}	2026-10-10 03:16:09.133514+05:30
123	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction", "reason": "42P08"}	2026-10-10 03:16:09.952508+05:30
124	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/conrad-bengaluru", "reason": "42P08"}	2026-10-10 03:16:10.234844+05:30
125	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/loya", "reason": "42P08"}	2026-10-10 03:16:10.682229+05:30
126	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/spicy-duck", "reason": "42P08"}	2026-10-10 03:16:11.026677+05:30
127	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions", "reason": "42P08"}	2026-10-10 03:16:11.370899+05:30
128	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/the-blue-bar", "reason": "42P08"}	2026-10-10 03:16:11.727676+05:30
129	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/gateway-bekal", "reason": "42P08"}	2026-10-10 03:16:12.177878+05:30
130	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/zhen-zhu", "reason": "42P08"}	2026-10-10 03:16:12.515699+05:30
131	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/capital-kitchen", "reason": "42P08"}	2026-10-10 03:16:12.8603+05:30
132	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/the-tea-lounge", "reason": "42P08"}	2026-10-10 03:16:13.199124+05:30
133	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction", "reason": "42P08"}	2026-10-10 03:16:13.551629+05:30
134	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/404", "reason": "42P08"}	2026-10-10 03:16:13.989187+05:30
135	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/", "reason": "42P08"}	2026-10-10 03:16:14.302231+05:30
136	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/projects", "reason": "42P08"}	2026-10-10 03:16:14.63722+05:30
137	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/video", "reason": "42P08"}	2026-10-10 03:16:14.977013+05:30
138	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/about", "reason": "42P08"}	2026-10-10 03:16:15.322942+05:30
139	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/contact", "reason": "42P08"}	2026-10-10 03:16:15.875612+05:30
140	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/carrer", "reason": "42P08"}	2026-10-10 03:16:16.211354+05:30
141	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 81, "endpoints_found": 28, "pages_discovered": 28, "requests_analyzed": 28}	2026-10-10 03:16:16.333076+05:30
27	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 02:12:52.445511+05:30
28	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://terminalonestudio.com/"}	2026-10-10 02:13:02.496469+05:30
29	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/", "reason": "error"}	2026-10-10 02:13:02.627731+05:30
30	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 02:13:02.647273+05:30
31	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 02:14:26.937117+05:30
32	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 02:14:27.098837+05:30
33	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 02:14:27.110929+05:30
34	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 02:43:39.97471+05:30
35	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "error"}	2026-10-10 02:43:40.178076+05:30
36	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 0, "endpoints_found": 1, "pages_discovered": 1, "requests_analyzed": 1}	2026-10-10 02:43:40.192586+05:30
37	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 02:59:29.397202+05:30
38	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 02:59:29.606086+05:30
39	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 02:59:30.055821+05:30
40	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 02:59:30.395978+05:30
41	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 02:59:30.842629+05:30
42	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 02:59:31.18997+05:30
43	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 02:59:31.535069+05:30
44	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 02:59:31.886397+05:30
45	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 02:59:32.236664+05:30
46	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 02:59:32.675878+05:30
47	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 02:59:33.044531+05:30
48	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 02:59:33.492876+05:30
49	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 02:59:33.826956+05:30
50	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 02:59:34.304412+05:30
51	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 02:59:34.662963+05:30
52	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 02:59:35.016023+05:30
53	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 02:59:35.969316+05:30
54	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 02:59:36.314307+05:30
55	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 02:59:36.646509+05:30
56	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 02:59:37.014863+05:30
57	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 02:59:37.363065+05:30
58	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 02:59:37.692294+05:30
59	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 02:59:38.09683+05:30
60	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 02:59:38.493555+05:30
61	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 02:59:38.875123+05:30
62	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 02:59:39.270201+05:30
63	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 02:59:39.649+05:30
64	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 02:59:40.043279+05:30
65	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 02:59:40.44579+05:30
66	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 02:59:40.824901+05:30
67	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 02:59:41.205816+05:30
68	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 02:59:41.580424+05:30
69	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 02:59:41.935685+05:30
70	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 02:59:42.312695+05:30
71	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 02:59:42.808097+05:30
72	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 02:59:43.174977+05:30
73	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 02:59:43.536801+05:30
74	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 02:59:43.884824+05:30
75	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 02:59:44.267188+05:30
76	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 02:59:44.640496+05:30
77	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 02:59:44.989807+05:30
78	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 02:59:45.351904+05:30
79	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 02:59:45.732491+05:30
80	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 02:59:46.093431+05:30
81	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 02:59:46.487064+05:30
82	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 02:59:46.846346+05:30
83	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 02:59:47.205324+05:30
84	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 02:59:47.563566+05:30
85	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 02:59:47.921434+05:30
86	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 02:59:48.271373+05:30
87	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 02:59:48.63159+05:30
88	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 02:59:48.983523+05:30
89	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 02:59:49.434248+05:30
90	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 02:59:49.784966+05:30
91	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 02:59:50.111337+05:30
92	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 02:59:50.560313+05:30
93	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 02:59:51.01394+05:30
94	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 02:59:51.362214+05:30
95	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 02:59:51.710306+05:30
96	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 02:59:52.073095+05:30
97	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 02:59:52.45964+05:30
98	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 02:59:52.950895+05:30
99	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 02:59:53.139136+05:30
205	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 04:14:19.909017+05:30
206	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 04:14:20.16173+05:30
207	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 04:14:20.501586+05:30
208	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 04:14:20.847741+05:30
209	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 04:14:21.19167+05:30
210	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 04:14:21.53613+05:30
211	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 04:14:21.876913+05:30
212	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 04:14:22.22065+05:30
213	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 04:14:22.566952+05:30
214	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 04:14:22.90203+05:30
215	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 04:14:23.246598+05:30
216	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 04:14:23.594154+05:30
217	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 04:14:23.959087+05:30
218	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 04:14:24.43201+05:30
219	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 04:14:24.789295+05:30
220	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 04:14:25.138916+05:30
221	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 04:14:25.690328+05:30
222	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 04:14:26.037598+05:30
223	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 04:14:26.384182+05:30
224	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 04:14:26.741007+05:30
225	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 04:14:27.132037+05:30
226	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 04:14:27.606321+05:30
227	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 04:14:28.009494+05:30
228	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 04:14:28.401289+05:30
229	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 04:14:28.779627+05:30
230	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 04:14:29.181366+05:30
231	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 04:14:29.566695+05:30
232	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 04:14:29.968729+05:30
233	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 04:14:30.362866+05:30
234	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 04:14:30.836435+05:30
235	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 04:14:31.221389+05:30
236	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 04:14:31.628191+05:30
237	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 04:14:32.018421+05:30
238	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 04:14:32.397377+05:30
239	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 04:14:32.769275+05:30
240	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:14:33.236927+05:30
241	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 04:14:33.696158+05:30
242	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 04:14:34.043603+05:30
243	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 04:14:34.434035+05:30
244	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 04:14:34.83936+05:30
245	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:14:35.196329+05:30
246	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:14:35.575634+05:30
247	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:14:36.0662+05:30
248	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 04:14:36.441314+05:30
249	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:14:36.92767+05:30
250	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 04:14:37.28083+05:30
251	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 04:14:37.646476+05:30
252	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 04:14:38.082101+05:30
253	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 04:14:38.431096+05:30
254	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 04:14:38.801168+05:30
255	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 04:14:39.163086+05:30
256	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 102, "endpoints_found": 50, "pages_discovered": 50, "requests_analyzed": 50}	2026-10-10 04:14:39.295598+05:30
191	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 03:27:18.891535+05:30
142	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 03:27:00.65374+05:30
143	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 03:27:00.889148+05:30
144	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 03:27:01.251441+05:30
145	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 03:27:01.598403+05:30
146	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 03:27:01.955235+05:30
147	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 03:27:02.297605+05:30
148	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 03:27:02.641105+05:30
149	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 03:27:02.994605+05:30
150	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 03:27:03.33369+05:30
151	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 03:27:03.670264+05:30
152	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 03:27:04.014911+05:30
153	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 03:27:04.354125+05:30
154	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 03:27:04.830469+05:30
155	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 03:27:05.141567+05:30
156	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 03:27:05.487359+05:30
157	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 03:27:05.95008+05:30
158	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 03:27:06.602738+05:30
159	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 03:27:06.946281+05:30
160	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 03:27:07.295934+05:30
161	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 03:27:07.662944+05:30
162	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 03:27:08.010774+05:30
163	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 03:27:08.371381+05:30
164	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 03:27:08.765341+05:30
165	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 03:27:09.12582+05:30
166	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 03:27:09.495992+05:30
167	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 03:27:09.887881+05:30
168	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 03:27:10.279807+05:30
169	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 03:27:10.665406+05:30
170	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 03:27:11.061441+05:30
171	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 03:27:11.448184+05:30
172	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 03:27:11.843964+05:30
173	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 03:27:12.236936+05:30
174	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 03:27:12.639465+05:30
175	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 03:27:12.995842+05:30
176	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 03:27:13.391554+05:30
177	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 03:27:13.746273+05:30
178	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 03:27:14.112782+05:30
179	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 03:27:14.479956+05:30
180	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 03:27:14.865315+05:30
181	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 03:27:15.253393+05:30
182	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 03:27:15.616638+05:30
183	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 03:27:15.972628+05:30
184	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 03:27:16.354091+05:30
185	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 03:27:16.73287+05:30
186	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 03:27:17.09964+05:30
187	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 03:27:17.451649+05:30
188	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 03:27:17.814981+05:30
189	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 03:27:18.16723+05:30
190	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 03:27:18.525883+05:30
192	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 03:27:19.242689+05:30
193	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 03:27:19.611677+05:30
194	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 03:27:19.95559+05:30
195	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 03:27:20.310295+05:30
196	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 03:27:20.770761+05:30
197	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 03:27:21.087583+05:30
198	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 03:27:21.444964+05:30
199	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 03:27:21.800908+05:30
200	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 03:27:22.145309+05:30
201	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 03:27:22.607833+05:30
202	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 03:27:22.98098+05:30
203	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 03:27:23.375128+05:30
204	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 03:27:23.526532+05:30
259	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 04:15:53.782764+05:30
257	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 04:15:53.222771+05:30
258	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 04:15:53.356558+05:30
260	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 04:15:54.114207+05:30
261	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 04:15:54.445506+05:30
262	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 04:15:54.783328+05:30
263	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 04:15:55.115267+05:30
264	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 04:15:55.466451+05:30
265	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 04:15:55.801688+05:30
266	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 04:15:56.153529+05:30
267	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 04:15:56.48487+05:30
268	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 04:15:56.825059+05:30
269	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 04:15:57.180443+05:30
270	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 04:15:57.541104+05:30
271	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 04:15:57.896707+05:30
272	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 04:15:58.252802+05:30
273	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 04:15:58.712014+05:30
274	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 04:15:59.054923+05:30
275	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 04:15:59.396052+05:30
276	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 04:15:59.754129+05:30
277	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 04:16:00.099069+05:30
278	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 04:16:00.46183+05:30
279	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 04:16:00.841517+05:30
280	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 04:16:01.227356+05:30
281	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 04:16:01.607287+05:30
282	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 04:16:01.989414+05:30
283	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 04:16:02.420034+05:30
284	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 04:16:02.804878+05:30
285	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 04:16:03.185731+05:30
286	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 04:16:03.672566+05:30
287	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 04:16:04.052218+05:30
288	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 04:16:04.54058+05:30
289	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 04:16:04.932928+05:30
290	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 04:16:05.307829+05:30
291	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 04:16:05.776975+05:30
292	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:16:06.129395+05:30
293	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 04:16:06.484073+05:30
294	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 04:16:06.834301+05:30
295	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 04:16:07.221023+05:30
296	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 04:16:07.610999+05:30
297	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:16:07.975659+05:30
298	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:16:08.333516+05:30
299	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:16:08.719516+05:30
300	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 04:16:09.117675+05:30
301	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:16:09.508452+05:30
302	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 04:16:09.856484+05:30
303	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 04:16:10.214818+05:30
304	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 04:16:10.576266+05:30
305	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 04:16:10.932037+05:30
306	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 04:16:11.396185+05:30
307	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 04:16:11.738053+05:30
308	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 04:16:12.091805+05:30
309	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 04:16:12.535697+05:30
310	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 04:16:12.884894+05:30
311	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 04:16:13.243901+05:30
312	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 04:16:13.588328+05:30
313	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 04:16:13.94149+05:30
314	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:16:14.290735+05:30
315	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 04:16:14.63734+05:30
316	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 04:16:14.99389+05:30
317	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:16:15.374714+05:30
318	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:16:15.75136+05:30
319	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 04:16:15.88315+05:30
320	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 04:21:59.250101+05:30
321	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 04:21:59.506522+05:30
322	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 04:21:59.849189+05:30
323	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 04:22:00.192954+05:30
324	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 04:22:00.539956+05:30
325	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 04:22:00.979124+05:30
326	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 04:22:01.311079+05:30
327	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 04:22:01.643232+05:30
328	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 04:22:01.986139+05:30
329	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 04:22:02.318679+05:30
330	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 04:22:02.657637+05:30
331	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 04:22:02.998177+05:30
332	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 04:22:03.479478+05:30
333	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 04:22:03.840102+05:30
334	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 04:22:04.214777+05:30
335	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 04:22:04.58385+05:30
336	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 04:22:05.217448+05:30
337	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 04:22:05.558572+05:30
338	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 04:22:05.899251+05:30
339	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 04:22:06.247529+05:30
340	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 04:22:06.606204+05:30
341	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 04:22:06.957302+05:30
342	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 04:22:07.335614+05:30
343	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 04:22:07.715939+05:30
344	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 04:22:08.089238+05:30
345	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 04:22:08.481701+05:30
346	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 04:22:08.873+05:30
347	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 04:22:09.272201+05:30
348	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 04:22:09.643662+05:30
349	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 04:22:10.011677+05:30
350	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 04:22:10.397007+05:30
351	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 04:22:10.778665+05:30
352	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 04:22:11.164299+05:30
353	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 04:22:11.552736+05:30
354	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 04:22:11.91759+05:30
355	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:22:12.272457+05:30
356	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 04:22:12.630461+05:30
357	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 04:22:12.986279+05:30
358	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 04:22:13.37526+05:30
359	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 04:22:13.752726+05:30
360	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:22:14.137704+05:30
361	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:22:14.511305+05:30
362	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:22:14.901531+05:30
363	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 04:22:15.293858+05:30
364	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:22:15.68585+05:30
365	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 04:22:16.043035+05:30
366	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:16.385915+05:30
367	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:16.746888+05:30
368	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:17.133131+05:30
369	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 04:22:17.492154+05:30
370	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 04:22:17.857319+05:30
371	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 04:22:18.2083+05:30
372	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 04:22:18.54391+05:30
373	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 04:22:18.903318+05:30
374	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 04:22:19.361171+05:30
375	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 04:22:19.692287+05:30
376	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 04:22:20.036763+05:30
377	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:22:20.382753+05:30
378	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 04:22:20.747233+05:30
379	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 04:22:21.112264+05:30
380	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:22:21.482392+05:30
381	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:22:21.8661+05:30
382	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 04:22:22.0278+05:30
383	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 04:22:27.675932+05:30
384	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 04:22:27.776591+05:30
385	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 04:22:28.119995+05:30
386	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 04:22:28.464639+05:30
387	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 04:22:28.804441+05:30
388	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 04:22:29.148051+05:30
389	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 04:22:29.487566+05:30
390	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 04:22:29.951941+05:30
391	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 04:22:30.284919+05:30
392	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf", "reason": "42P08"}	2026-10-10 04:22:30.63053+05:30
393	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/OpenSans.ttf", "reason": "42P08"}	2026-10-10 04:22:31.076178+05:30
394	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf", "reason": "42P08"}	2026-10-10 04:22:31.411313+05:30
395	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography.php", "reason": "42P08"}	2026-10-10 04:22:31.780385+05:30
396	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films.php", "reason": "42P08"}	2026-10-10 04:22:32.141585+05:30
397	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/faq.php", "reason": "42P08"}	2026-10-10 04:22:32.501139+05:30
398	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/about.php", "reason": "42P08"}	2026-10-10 04:22:32.857896+05:30
399	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/contact.php", "reason": "42P08"}	2026-10-10 04:22:33.238646+05:30
400	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/swiper-bundle.min.js", "reason": "42P08"}	2026-10-10 04:22:33.573755+05:30
401	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/aos.js", "reason": "42P08"}	2026-10-10 04:22:33.916579+05:30
402	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/fallback;", "reason": "42P08"}	2026-10-10 04:22:34.283635+05:30
403	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/featsBg.find(img", "reason": "42P08"}	2026-10-10 04:22:34.635179+05:30
404	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Btest.img%7D", "reason": "42P08"}	2026-10-10 04:22:34.993187+05:30
405	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayush---sneha.php", "reason": "42P08"}	2026-10-10 04:22:35.374881+05:30
406	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 04:22:35.749994+05:30
407	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/bride.php", "reason": "42P08"}	2026-10-10 04:22:36.126098+05:30
408	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/chadani---chirag.php", "reason": "42P08"}	2026-10-10 04:22:36.506458+05:30
409	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/j---p.php", "reason": "42P08"}	2026-10-10 04:22:36.885928+05:30
410	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/megha---ankit.php", "reason": "42P08"}	2026-10-10 04:22:37.479933+05:30
411	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/neel---mike.php", "reason": "42P08"}	2026-10-10 04:22:37.849373+05:30
412	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/nikaah.php", "reason": "42P08"}	2026-10-10 04:22:38.227271+05:30
413	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/ninad---rupali.php", "reason": "42P08"}	2026-10-10 04:22:38.708806+05:30
414	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/prerita---bhairav.php", "reason": "42P08"}	2026-10-10 04:22:39.096845+05:30
415	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/r---o.php", "reason": "42P08"}	2026-10-10 04:22:39.584664+05:30
416	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/s---a.php", "reason": "42P08"}	2026-10-10 04:22:39.955286+05:30
417	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/wedding-highlights.php", "reason": "42P08"}	2026-10-10 04:22:40.32905+05:30
418	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:22:40.684036+05:30
419	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BlinkUrl%7D", "reason": "42P08"}	2026-10-10 04:22:41.046217+05:30
420	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BfallbackImg%7D", "reason": "42P08"}	2026-10-10 04:22:41.397695+05:30
421	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 04:22:41.773293+05:30
422	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php", "reason": "42P08"}	2026-10-10 04:22:42.154199+05:30
423	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:22:42.498964+05:30
424	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neeel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:22:42.842584+05:30
425	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:22:43.213144+05:30
426	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/ninad-and-rupali-wedding.php", "reason": "42P08"}	2026-10-10 04:22:43.596869+05:30
427	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php", "reason": "42P08"}	2026-10-10 04:22:43.982987+05:30
428	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BthumbnailFallback%7D", "reason": "42P08"}	2026-10-10 04:22:44.32881+05:30
429	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:44.685222+05:30
430	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:45.045562+05:30
431	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;", "reason": "42P08"}	2026-10-10 04:22:45.524668+05:30
432	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7Bsrc%7D", "reason": "42P08"}	2026-10-10 04:22:45.880736+05:30
433	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/defaultImage;", "reason": "42P08"}	2026-10-10 04:22:46.226753+05:30
434	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/$%7BdefaultImage%7D", "reason": "42P08"}	2026-10-10 04:22:46.574317+05:30
435	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/img/bg/contact-2400.webp", "reason": "42P08"}	2026-10-10 04:22:46.903081+05:30
436	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 04:22:47.251769+05:30
437	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/thankyou.php", "reason": "42P08"}	2026-10-10 04:22:47.603855+05:30
438	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/glightbox.min.css", "reason": "42P08"}	2026-10-10 04:22:48.046942+05:30
439	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/resolveUrl(img.src);", "reason": "42P08"}	2026-10-10 04:22:48.41524+05:30
440	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/$%7Bfallback%7D", "reason": "42P08"}	2026-10-10 04:22:48.7668+05:30
441	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/js/glightbox.min.js", "reason": "42P08"}	2026-10-10 04:22:49.209483+05:30
442	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1", "reason": "42P08"}	2026-10-10 04:22:49.555274+05:30
443	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-teaser.php", "reason": "42P08"}	2026-10-10 04:22:50.037147+05:30
444	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/neel-and-mike-highlights.php", "reason": "42P08"}	2026-10-10 04:22:50.418304+05:30
445	010752b0-dc79-4ad4-8293-6f4f7da62c57	\N	info	scan_completed	Passive scan completed.	\N	\N	{"findings": 126, "endpoints_found": 61, "pages_discovered": 61, "requests_analyzed": 61}	2026-10-10 04:22:50.550352+05:30
446	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	info	scan_queued	Passive scan queued.	\N	\N	{"scan_type": "standard", "target_url": "https://thephotopunditz.com/"}	2026-10-10 04:26:35.101626+05:30
447	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/", "reason": "42P08"}	2026-10-10 04:26:35.232256+05:30
448	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.ico", "reason": "42P08"}	2026-10-10 04:26:35.562178+05:30
449	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/favicon.png", "reason": "42P08"}	2026-10-10 04:26:35.892312+05:30
450	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/output.css", "reason": "42P08"}	2026-10-10 04:26:36.237087+05:30
451	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/aos.css", "reason": "42P08"}	2026-10-10 04:26:36.577997+05:30
452	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/css/swiper-bundle.min.css", "reason": "42P08"}	2026-10-10 04:26:37.026849+05:30
453	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/BodoniModa.ttf", "reason": "42P08"}	2026-10-10 04:26:37.355917+05:30
454	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf", "reason": "42P08"}	2026-10-10 04:26:37.699351+05:30
469	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/photography/aayushi---raahat.php", "reason": "42P08"}	2026-10-10 04:26:43.121859+05:30
484	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/films/aayush-and-sneha-teaser.php", "reason": "42P08"}	2026-10-10 04:26:48.824962+05:30
499	010752b0-dc79-4ad4-8293-6f4f7da62c57	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://thephotopunditz.com/backend/form.php", "reason": "42P08"}	2026-10-10 04:26:54.480977+05:30
515	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/carrer", "reason": "42P08"}	2026-10-10 04:27:17.532+05:30
530	010752b0-dc79-4ad4-8293-6f4f7da62c57	e684818b-89b5-4930-9639-d09d51978b3d	warning	scan_request_failed	A page could not be fetched during scanning.	\N	\N	{"url": "https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction", "reason": "42P08"}	2026-10-10 04:27:22.76889+05:30
\.


--
-- TOC entry 5325 (class 0 OID 33941)
-- Dependencies: 225
-- Data for Name: ai_predictions; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.ai_predictions (id, scan_id, input_type, prediction, confidence, model_name, created_at) FROM stdin;
\.


--
-- TOC entry 5341 (class 0 OID 35142)
-- Dependencies: 242
-- Data for Name: alert_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_audit_logs (id, alert_id, user_id, action, previous_value, new_value, metadata, created_at) FROM stdin;
50114baa-373c-456d-8397-ec7ca232b542	2ee7574d-c7d6-4256-8f4d-03371a79a8ed	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:42.682959+05:30
633740ef-5726-4c7e-a4f4-2451dd69ada6	2c8d3c84-74ba-49bb-9281-0b0217b33dab	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:43.058593+05:30
4ed92927-24fd-4f18-a14d-d2e6d17e7962	4465d97a-c982-41ac-b4c9-821d76af6112	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:43.807957+05:30
501a0acd-0bd1-4a23-918c-e67623cc63bb	08679629-c998-4533-836f-22f94ea4358f	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:44.182451+05:30
bb8e0be6-9e16-4be3-84f7-52a4c2ad1d19	06c34b7d-0a0b-4eb9-8423-a80c1f3fe688	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:44.572241+05:30
4af2384b-bfb8-4bc7-bb0b-d84c387ca43e	d0b5251f-4a24-44fe-ace4-fb844294cfa9	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:44.949339+05:30
a3294c02-90b1-40a8-8f98-386749ec28a1	80dff846-75ab-4764-a038-d7cde63990bf	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:45.824415+05:30
11514285-43ce-4473-ad10-0d6213989377	d23e0b3e-0203-4f1d-a7cc-3d7e451da73e	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:46.19282+05:30
2b1ae660-5046-491f-b499-d95a3cd38224	9ef303a1-2521-4f88-9544-802f0ab4397e	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:46.580978+05:30
ed5bdf1a-2df0-4104-b612-e1b1fabf330a	64d35c53-3cfa-47e3-96ce-5da05a0b8716	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:26:46.964696+05:30
058ffed3-3fe7-4470-a904-1162f89f7a94	3fadf05c-8acf-4a97-ae2e-3386c0f2a92e	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:27:17.818187+05:30
3da4b720-5cea-4a3f-a039-8c40a88d574f	1054429c-275a-48be-a284-d9ca06a8a149	\N	alert_created	\N	new	{"rule_id": "RULE-SQLI-001", "severity": "high", "classification": "SQL Injection"}	2026-10-10 04:27:20.640862+05:30
\.


--
-- TOC entry 5340 (class 0 OID 35116)
-- Dependencies: 241
-- Data for Name: alert_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alert_notes (id, alert_id, author_id, note, created_at) FROM stdin;
\.


--
-- TOC entry 5339 (class 0 OID 35059)
-- Dependencies: 240
-- Data for Name: alerts; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.alerts (id, scan_id, traffic_log_id, correlation_key, rule_id, classification, severity, confidence, source_ip, target_url, endpoint, http_method, status, occurrence_count, description, evidence, analyst_notes, first_seen_at, last_seen_at, created_at, updated_at, assigned_to) FROM stdin;
2ee7574d-c7d6-4256-8f4d-03371a79a8ed	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	415	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/aayush---sneha.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/aayush---sneha.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/aayush---sneha.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:42.681888+05:30	2026-10-10 04:26:42.681888+05:30	2026-10-10 04:26:42.681888+05:30	2026-10-10 04:26:42.681888+05:30	\N
2c8d3c84-74ba-49bb-9281-0b0217b33dab	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	416	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/aayushi---raahat.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/aayushi---raahat.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/aayushi---raahat.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:43.057851+05:30	2026-10-10 04:26:43.057851+05:30	2026-10-10 04:26:43.057851+05:30	2026-10-10 04:26:43.057851+05:30	\N
4465d97a-c982-41ac-b4c9-821d76af6112	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	418	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/chadani---chirag.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/chadani---chirag.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/chadani---chirag.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:43.807265+05:30	2026-10-10 04:26:43.807265+05:30	2026-10-10 04:26:43.807265+05:30	2026-10-10 04:26:43.807265+05:30	\N
08679629-c998-4533-836f-22f94ea4358f	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	419	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/j---p.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/j---p.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/j---p.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:44.181629+05:30	2026-10-10 04:26:44.181629+05:30	2026-10-10 04:26:44.181629+05:30	2026-10-10 04:26:44.181629+05:30	\N
06c34b7d-0a0b-4eb9-8423-a80c1f3fe688	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	420	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/megha---ankit.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/megha---ankit.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/megha---ankit.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:44.57144+05:30	2026-10-10 04:26:44.57144+05:30	2026-10-10 04:26:44.57144+05:30	2026-10-10 04:26:44.57144+05:30	\N
d0b5251f-4a24-44fe-ace4-fb844294cfa9	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	421	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/neel---mike.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/neel---mike.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/neel---mike.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:44.948543+05:30	2026-10-10 04:26:44.948543+05:30	2026-10-10 04:26:44.948543+05:30	2026-10-10 04:26:44.948543+05:30	\N
80dff846-75ab-4764-a038-d7cde63990bf	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	423	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/ninad---rupali.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/ninad---rupali.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/ninad---rupali.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:45.823609+05:30	2026-10-10 04:26:45.823609+05:30	2026-10-10 04:26:45.823609+05:30	2026-10-10 04:26:45.823609+05:30	\N
d23e0b3e-0203-4f1d-a7cc-3d7e451da73e	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	424	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/prerita---bhairav.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/prerita---bhairav.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/prerita---bhairav.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:46.191796+05:30	2026-10-10 04:26:46.191796+05:30	2026-10-10 04:26:46.191796+05:30	2026-10-10 04:26:46.191796+05:30	\N
9ef303a1-2521-4f88-9544-802f0ab4397e	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	425	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/r---o.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/r---o.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/r---o.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:46.580282+05:30	2026-10-10 04:26:46.580282+05:30	2026-10-10 04:26:46.580282+05:30	2026-10-10 04:26:46.580282+05:30	\N
64d35c53-3cfa-47e3-96ce-5da05a0b8716	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	426	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78:RULE-SQLI-001:127.0.0.1:/photography/s---a.php	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/photography/s---a.php	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/photography/s---a.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:26:46.963981+05:30	2026-10-10 04:26:46.963981+05:30	2026-10-10 04:26:46.963981+05:30	2026-10-10 04:26:46.963981+05:30	\N
3fadf05c-8acf-4a97-ae2e-3386c0f2a92e	e684818b-89b5-4930-9639-d09d51978b3d	461	e684818b-89b5-4930-9639-d09d51978b3d:RULE-SQLI-001:127.0.0.1:/projects/taj--pan-india	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/projects/taj--pan-india	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/projects/taj--pan-india", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:27:17.81751+05:30	2026-10-10 04:27:17.81751+05:30	2026-10-10 04:27:17.81751+05:30	2026-10-10 04:27:17.81751+05:30	\N
1054429c-275a-48be-a284-d9ca06a8a149	e684818b-89b5-4930-9639-d09d51978b3d	469	e684818b-89b5-4930-9639-d09d51978b3d:RULE-SQLI-001:127.0.0.1:/projects/raajsa-kumbhalgarh---ihcl-seleqtions	RULE-SQLI-001	SQL Injection	high	0.7	127.0.0.1	\N	/projects/raajsa-kumbhalgarh---ihcl-seleqtions	GET	new	1	SQL comment delimiter detected	{"matchedContext": "/projects/raajsa-kumbhalgarh---ihcl-seleqtions", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}	\N	2026-10-10 04:27:20.640177+05:30	2026-10-10 04:27:20.640177+05:30	2026-10-10 04:27:20.640177+05:30	2026-10-10 04:27:20.640177+05:30	\N
\.


--
-- TOC entry 5343 (class 0 OID 35202)
-- Dependencies: 244
-- Data for Name: finding_audit_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finding_audit_logs (id, finding_id, user_id, action, previous_value, new_value, metadata, created_at) FROM stdin;
0693ac38-01c1-4020-b9c4-e19a672de3fd	b8d043f3-aae4-4240-8be3-4e4ef542f295	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.36138+05:30
1fc8cf14-c546-4550-b4e2-8047dc5f2233	496d9f8e-6530-4fa5-ab15-d3e877d1478e	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.362969+05:30
f7c7061a-db8c-4e63-b275-bd99dd22dcad	f45d70f7-bded-4b0d-a849-7b0bfc80be81	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.364205+05:30
c7ddb0eb-7915-46b2-ae4f-203ce6db0b25	7488c3a3-e600-4749-920d-cedb48aca500	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.365323+05:30
2eea8cea-e383-4375-8ca4-c2b08143bf87	b19c7bd9-fbcf-4ca7-92b5-34d1d11db3d4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.366432+05:30
36297d5d-b1b1-408e-8bee-e52160531191	8e2ac041-12e7-47ff-be70-b90d8b9f5028	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.367539+05:30
26c7cd40-405a-4f3d-886a-d8676c4e863f	3d84f41a-b4ec-4f94-a194-27c022a68346	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.368611+05:30
7ef087d7-6000-45dd-9e1a-8a49ff5be961	616f718b-3ad4-4039-be69-cfa4514d9de8	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.369641+05:30
d5588c04-c6b8-49ea-9cce-eabd86d68340	c612a004-a36f-4043-aadf-95af54382cb6	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.370663+05:30
a305db04-f5a7-426a-bda3-b841adf8e1e3	447ff835-53cb-4694-89bf-ead0384c1ed4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.371677+05:30
11106eba-c1a4-415f-a7fa-fce601985009	b46539e8-1066-4449-b9ae-48ffbdd06b79	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.372699+05:30
258cdad7-3b66-4aa7-9a03-373a6dfb043a	a771c95f-fc0d-4ccf-802a-a70e31d5edd7	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.373902+05:30
6f66d860-4f2d-44d9-8f68-95af68a5d797	181bfa33-442a-4432-bfa5-ec1d223d0cbd	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.375191+05:30
fa544a5d-b9b4-407b-ab33-e8c12f1fbc9f	c32d993a-5131-4922-8ad0-18063c8f4706	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.376265+05:30
ad97dbe4-dd4c-4e60-9b23-11441f321154	3d745fa0-151e-4151-b3be-bcdac0e8925d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.377329+05:30
3a207cd9-9440-4769-80bc-a118604d30ed	df827556-3586-4199-889a-f9b41b84d6fe	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.378348+05:30
50860df2-c96a-43d4-9b7e-4e445bc5e7ca	5dbf7b21-558e-4d43-9170-a960c3d13d53	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.379362+05:30
84ecff10-4052-4294-a54c-51df388ae5e5	a59afd72-a35b-4a06-87a0-4fd77748e85c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.380378+05:30
7ab559ed-0578-4723-8850-4eb1af58cd70	8c5d71fa-9162-4d9f-acde-7d69fe8fb738	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.381405+05:30
38eff639-1474-4738-9f1d-6308d8a32842	c5ad22f5-0ab6-4637-bcf3-7446dd1c2f8d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.382425+05:30
91ea8278-9274-40b9-b961-a122b33570c3	7ccc41d0-130b-4920-99db-f7e49ae54957	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.383439+05:30
dbfc860c-3a4e-434a-bc5f-a253c9f0f542	6a18a2aa-4c56-4946-9a63-f34c1c6b3cd4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.384645+05:30
dabe91b8-90b4-4c07-82db-1a2c83d43e93	adf12a6e-a55f-4fb0-a21f-19515c3189d6	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.385727+05:30
74446669-5189-4728-952a-17a0fc19a732	21378f17-7b0b-49a0-a11b-3b673c0a1766	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.386773+05:30
5134ad19-da9d-4472-a147-c2af24a8efac	cce9f62d-831c-4b5f-8ebb-1437ca65dd61	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.387842+05:30
b80c3cbf-6255-45c2-b68e-5f8dc60ca11e	0c03cbd5-18e7-4d13-8aeb-d9a1b926f956	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.38906+05:30
25199cfe-d5b3-4cbf-b07c-db3599d5ffcf	409143ca-b56f-4792-a277-352f8b5b0a2c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.39011+05:30
1a095ca5-30ec-417e-b3e8-749130998aa6	0ded09fe-a1f7-44f8-8013-1ad04cc1e42a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.391167+05:30
31173d50-50c5-4cf1-b828-18549f40d1a0	445ea95a-7c60-4f8a-abe4-ff95f44c9d52	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.392196+05:30
c1453dca-a93e-4bef-9f8d-fa65caf5a498	572606cb-5bc3-4bed-8dd7-fa305f905173	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.393235+05:30
0a658dcd-c580-47fe-8e4b-f98c95b0dfe9	ba3b4c09-872f-4f09-a163-b186f9d389e5	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.394276+05:30
5cd40794-4a94-404e-88b7-81b3775cbc13	0d86fae6-644c-4045-bd82-a902dca990c1	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.395328+05:30
46e939e3-f3cf-43c8-82d5-252e7a6600d5	c831dbd3-e217-4bad-9691-dc5a6e77f98b	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.396362+05:30
9ecad7da-05f2-4436-9abe-1ec1ab199c0d	6dae9427-2013-428e-b54a-42d80e64a463	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.397413+05:30
f24807cc-0de7-4ba2-9776-5f40c98f502f	73758529-cdcd-4e3a-bad4-1715ebe52b3b	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.398439+05:30
a335f642-00e2-44c0-a7d8-3d7ddc3deab5	f4ef0464-6cc5-421b-a639-81e50b747bfd	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.399471+05:30
04d348ad-d5ae-4bae-8fd4-98a2b74c2c7e	f04abc96-e47a-4617-8fcf-402de8969b48	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.400488+05:30
d02a11e5-720a-41a7-a065-40c70231ce98	cde34241-a190-43bb-8fb5-9688f7a5440f	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.401553+05:30
0702a977-da20-4324-b4ae-22897fa07004	951626e3-df41-431e-b5c6-876b59295264	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.402579+05:30
30642e7c-d341-4678-abeb-7021a8bdb809	29b23ed1-7359-4871-9676-2cc8c6133871	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.404129+05:30
239f8d42-0689-4a11-a83a-89e63f3908ef	ed3e69dd-0311-4dd4-8669-b5177eca28aa	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.405901+05:30
396bae49-5256-4bb4-ba3a-e626f222975a	b20f42cc-c314-42c0-a737-83c5448787ed	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.406996+05:30
adb3dc16-a178-4248-b7c8-470aa50e76f8	b3b354ec-3857-42e8-9d7a-37b1ec4bd25e	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.408061+05:30
71e5c9ff-85a4-45a1-928a-afa20e5a860c	22c9d0fc-96c3-4aab-acb4-c8c65624ad6a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.409092+05:30
8798f728-8428-43cc-80ec-2a364ddb6057	50129f4b-eb24-48d4-b49e-2b797b29a65a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.410118+05:30
cdcbc394-c46f-4951-b2ca-4c3b2146c230	39a8a76a-b172-4b0b-a3c9-21f11e2cd864	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.411138+05:30
e484110d-50ec-42bc-a2ee-57c2b2a8c742	a8c73430-4197-4b94-82e8-57ce435685dc	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.412192+05:30
c3f13c70-e611-462c-b89b-cac295b93b98	94daa859-5c59-4be3-8f2b-a2ef48fc703d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.413215+05:30
8de7e84e-d4f6-4915-9c1f-03bd8148379b	0c550814-d628-4f9d-a793-373fb42c2ac7	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.41429+05:30
3da30c11-c513-41ac-be1a-e1cf52e4d180	06e0dfa1-6cf8-4568-a4a8-74c1fd9dbf1d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.415446+05:30
4b709c03-8774-454b-a996-76eeffbe2c91	799be6a6-5694-484d-8ed4-5ae4d50ccf10	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.416479+05:30
ab49d9b2-e893-4f30-a4b9-1374316121d9	c8ed774f-ecf0-4a01-a6c6-d9677d534c29	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.417497+05:30
3e4e8d9b-a400-42ca-b337-a2bd9f253967	e0f56ee9-b567-41bc-b553-ba4c64993537	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.418568+05:30
736f984a-6d0a-4e95-9b9f-9702322958e7	1599933f-33f2-42b9-8e51-2d3824d66c5c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.419584+05:30
72b63a06-f2cf-4d00-8891-f05befd741b6	40ec776e-3613-4eb1-9b9e-548ea78fc14c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.420908+05:30
5401b22c-bc89-4298-a17d-b4ea77bbd5ae	b3fac1b7-f7f1-4900-8bf4-1bbd60abdb42	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.421955+05:30
61f0186b-e6a4-4aac-848f-ddebf2dd5364	7580179f-8285-482c-a490-2a0d73af5960	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.422981+05:30
0c8cfa48-bb16-4882-bc70-1140f4bb883f	b6d39b21-3260-482a-a5e7-bcd702c198ca	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.424017+05:30
8056522d-a825-4091-ab6e-3dcb2c55fb7f	f85d6b93-4180-406a-a8a2-5741e327e56c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.425068+05:30
9df13ac1-62a7-49aa-9888-96129c72b77c	13eb097f-ad5d-4bb8-a88d-55cb19187490	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.426109+05:30
d55dd7de-8b51-40df-b20a-080c01dd7de3	10532726-9715-4350-9981-9654e3c5f010	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.42714+05:30
5f138a9f-b68c-410f-926b-1240acf9cae6	a59cb1e3-aea7-46bc-9dbf-2d748d9b8f3c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.428218+05:30
a704f151-bfc2-4df6-936c-9d5f8de52258	d3313ee6-8ee3-4277-bac0-8e902a13d736	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.42924+05:30
2f96238e-de25-4877-a7f9-400d168ff5ab	90d227a6-da3a-4e0a-9ae1-70cf499b0d4c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.430273+05:30
3ad09728-43eb-4cdf-a282-9513a974e93a	14f5df17-6f03-45b0-b5af-707380e0461c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.431289+05:30
934dd651-84af-48cb-bb00-98b91cbc0df4	47f30541-3237-4138-a3be-02a5cbecb3cf	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.432307+05:30
438cf8c8-787c-46d7-a9f9-552e5914a318	d1995312-c44a-4412-aff1-49c996a613f0	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.433324+05:30
a50a1054-5ea7-4f97-85f3-8c42565d75a4	ce0a86ab-3dfb-44d5-9f58-a57a2ccc1f88	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.434366+05:30
833d1220-6f3c-4f0c-9690-b07f1578bd58	546500ac-a315-4726-8a82-0110b630cc15	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.435549+05:30
61406af1-69fc-4688-a3da-83e3cf35767f	b6a40db9-d4ff-4879-9285-2281fb328dde	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.436772+05:30
a539cee9-232a-4175-8a17-508eb3fc9287	f814b01d-24c6-4eb5-b6d9-cba7b8a83802	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.437858+05:30
22be0d72-116a-4ca2-9555-27ed04ea31e7	6850f576-9f36-4f8d-b265-89c6eeee5568	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.438901+05:30
784630d1-860c-4d8a-98f6-5655deac957d	57bb8925-fea6-4cd0-94bf-c89804308829	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.439925+05:30
72e36b8f-24b0-4b1c-af72-e588c0bb9f7f	f5a869c0-d4ee-4967-a8b5-df57e62122f4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.440979+05:30
80679aa2-4e36-4fd8-ac9f-381b7e4f37c4	22792de0-c1d3-4418-b3c6-c4b03e7c9e63	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.442013+05:30
8283bc66-d987-4bac-bb1b-99f89176aa8c	a3b9b8be-a199-4aa2-af3d-0cd0afe06dea	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.44304+05:30
4aed63b7-9119-4e3a-95a7-ece6411d53c5	e1ff06e7-558f-4972-83c1-317d730568d1	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.444075+05:30
2cdb3a37-f5b1-409f-8370-8230b1d393e9	0e1bd6b8-0f3d-4412-805a-e1b64fb12d20	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.445264+05:30
0183d54e-e59d-4eae-9b65-78a1d3a28890	7fcba045-b6dd-470c-b97f-3dc863e0e93d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.446316+05:30
9a7d935e-8e50-47c2-9a6f-01b0352e7df5	35c7865c-fdde-4e89-b013-c6defe846304	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.447395+05:30
a165be89-0a39-4c7f-810b-d66c21b39f15	88523cba-2a30-4fe2-8b65-bc271a987001	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.448418+05:30
486af1fa-934c-4664-8d7d-32999990c7a3	87bb6c9b-26cf-4c56-affd-86a960e59335	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.449457+05:30
5c94d455-0519-4cea-9721-3030f2e6138e	62cb59ff-f279-4176-8035-38277607cf49	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.450897+05:30
5623e32b-7ab1-4307-a7f7-ba83f6e249ed	bef5bf62-edba-4d75-a626-21d977f23993	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.45195+05:30
022ff2d5-5adf-499b-a258-236a8ad77ef4	38f9b028-2dda-4b79-b4b3-b4031ea1186b	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.452991+05:30
c9c28819-4b55-4407-ae9b-d99b3a447e60	bb84e75a-6385-470b-abcb-f2124e542e14	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.454048+05:30
718bb841-8ae2-443e-946d-6a08167fab26	0b6dab97-c40d-4f21-9bb6-701361d4c363	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.455105+05:30
76383079-d5dd-480e-bf74-b600ff3a30e4	d71e80b0-6e35-47d7-bcf9-8eeed19f3e2a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.456132+05:30
17979194-da41-4457-bba6-c07307d18794	cbc7ebee-9185-443b-935e-13d53a4ba4eb	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.457184+05:30
054f98c0-ddee-4560-bd38-05a23bb05900	0e807a94-3931-4101-b25b-a202aec5ae93	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.458204+05:30
cb02049f-df82-4f57-8c2e-3f4012b44bee	a625f0c4-5b5e-4a50-ab9a-6e733eb50f02	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.459257+05:30
feafbf4d-f318-4fe6-a29e-4d1724906624	7551b5fc-3351-4551-bb9f-61416118448a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.460279+05:30
b6494910-3d2a-42ba-be67-605fab30abd4	12ad24af-31c2-4cd7-bcb5-6864c8caca33	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.461298+05:30
e2086cd3-2b2c-42f4-86e4-465a68dcd868	d8dc483d-e872-44e8-8cd4-8e8c8e8e9b8c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.462318+05:30
1d60e3cd-8637-4428-afff-937939ca11c4	10b254eb-113b-4781-a730-a022bafbfe67	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.463339+05:30
7e98c5cb-5c8f-4d72-81e3-230b8cca6825	a4ec68a2-54c4-4e11-b2ef-dfc4a5454090	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.464381+05:30
70a5a0e6-18aa-4f4d-8273-cb5ae1c98f58	41a6a9e8-ac54-4042-84ab-c98be35f0680	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.465454+05:30
42dd5fa0-7ac9-4ef5-b8b7-676f78235782	22b99716-dcfb-47f2-bc07-d2180736218a	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.466824+05:30
2886c34d-73c1-4a39-b19f-9237de178cb7	95df6188-5ffa-46b4-a8e7-334d057a8043	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.467901+05:30
bfb6d104-d789-41d3-92fc-109ef7b72dc2	a2b3521b-d3d8-47fe-9f28-97a2e6412bc4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.46892+05:30
18f6062e-652e-4aec-a439-61a8cc4e2897	f2a25f2a-910d-47f1-8ae2-e71e1b4cf5de	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.46997+05:30
a4c2ceb1-6610-4534-a91e-0e859ebcd9b2	b2ee54a4-d2e4-4c30-8bee-c7951a4e01c3	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.470982+05:30
99782bc9-0232-4726-bea4-6c7bf6cad6ec	1464103d-a2dc-4d40-86c6-7e80c31b1826	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.471992+05:30
ba4ab2b9-9af4-408f-85bf-5145d114e27c	68808a17-98da-411d-8294-4cdd2e7c1d79	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.473004+05:30
1cf97da0-ca10-4bbe-bb33-73037156501e	bb6aeba9-d6d1-492a-bebe-4da0946fb458	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.474178+05:30
869d52af-baa6-4d26-bf49-edf1a3f859ff	e254ea68-46f2-4695-8f41-d646dcc92c62	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.475221+05:30
89635d04-7bd1-40bd-8832-582aaf3939c4	b672183d-7129-44ce-8c5e-6cdd5326c863	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.476247+05:30
a07358c6-1cb4-4483-bc42-ba8a4dba773c	77662bcb-190f-4d43-a916-789dd335c8e4	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.477263+05:30
ff69d254-f08a-4678-a9d1-1bfbdb91f64b	9b93544e-4d45-4c69-8578-e9b3a932e7b0	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.478277+05:30
130e70fe-f65d-4077-aabe-dcf9bdbd2880	c55418d6-9e74-4ecb-9758-b28d27437938	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.479332+05:30
5e2ed831-0b9b-4ec7-99eb-5f95cfd4afe1	a07aa924-ea62-4853-9b5a-d2e0d6228f02	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.480429+05:30
e06949ab-0929-4a1f-a97f-ddae377e0dbb	f636e529-0a0f-4dac-93ec-914f3d14d90c	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.481463+05:30
ee67fc68-b124-459c-96fd-161e9d092d0a	6e30ef0b-b2b9-4665-8a66-5e61d8002433	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.482572+05:30
60abd6d5-89cf-476a-89d6-b833c794b368	f8e49077-1958-4d0b-8328-18b7f4d8a464	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.483859+05:30
384d1a71-4bb3-4322-8e05-61e40e9c6a62	c427d5d3-dd1b-43bd-9be3-c55e2e85bce5	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.48492+05:30
6384a8a9-6455-4124-8d8a-558277e88584	1a933889-6e8f-4524-bb6f-29583251d470	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.485949+05:30
0f13b275-f7d9-4d8a-8de4-1c128c98f392	d73fbf06-6229-4c80-8ea9-fada7ca5523b	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.486977+05:30
4c95306c-6160-440f-a184-103dda9b7af7	6f7231e0-093b-4846-9980-6f0d245f1d3b	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.48802+05:30
e0b04ff1-b20b-4b36-9443-da6fac471294	1a92bbe7-3b9a-4c54-bd19-db914c60cc1f	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.489068+05:30
8fd82edf-888d-4d2d-97c5-ede25ef22afe	ebd9e83c-eca4-4002-8a21-42f7419e60b1	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.490205+05:30
5e2f4983-6aaa-4e5b-a079-1af36203779b	0aadad78-abc5-4114-8109-e6d2b3841cb5	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.491264+05:30
45609360-2ba0-4f99-b33e-1c0aa9edf26b	aac68567-fd8f-4e25-922d-7ca59e9e94db	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.492305+05:30
71bc15c9-303e-4237-9e95-dde186365e1d	decdea88-4d0d-4588-8228-e9ccc6cfd80d	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.493376+05:30
80e4beac-ff0c-4796-93a3-ca19d859273b	4710e047-72cc-4a92-aa82-3096fe2795fe	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.494423+05:30
5089133c-19b3-489e-8aaf-89e8b6fe5bf1	6d4ba5cb-8d92-43a4-bb3a-2b1461cdfde5	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.495493+05:30
fcadba59-ac2a-463e-b412-c9f612fac0af	7af3006c-daa3-4f02-b6d2-32b9571b4eb2	\N	finding_detected	\N	open	{}	2026-10-10 04:26:57.496527+05:30
5a42bd46-c2cb-4aeb-b257-f6edf09abaa2	a2df117b-6def-4832-8c6e-866c2bfae8e8	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.180025+05:30
7a0478a8-21d2-4de9-876f-1698ac86956e	17e7f166-5aba-4df7-8963-1d57ac594e16	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.18875+05:30
8a5f5e45-609a-4620-b0e4-1d64f05449bb	14cb1bac-079a-4e0e-a056-0a1b2ace6eb9	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.189962+05:30
9e14119a-5176-41f5-aa23-dbea6cfa129a	ef7f6ee4-e936-48ff-a15f-67a881c4ef6a	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.191259+05:30
f04d11c7-4061-43d9-a125-b4176d7e12d7	8a573f86-aa09-46a7-9e5b-e01f707c2c92	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.192409+05:30
1d1a557e-0ee8-47ef-a176-3addbdf568ef	49f5c68e-a19c-4556-ac4d-4334de46c5c0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.193587+05:30
21af5135-be22-4fbf-a619-34050205d937	b5fa2571-eeba-4a4c-9082-3c503a62d8b9	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.194977+05:30
d0b1279a-3dcf-4501-aa13-d84255ed9a90	4d8f4574-b7cf-4ca8-8014-1ee7d65b8b2e	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.196058+05:30
07fa89b3-56a5-439b-98f6-947437290afc	0a9f3ee1-7500-4b19-b54c-3754f27ea986	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.197078+05:30
dd0583f1-7f50-4b24-8115-e2613eecb7c0	b7e9c803-41fc-4e7d-a58a-de06ca21f2ec	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.198241+05:30
8ae21643-f748-46da-be95-121a9af3dc1a	6f6eb2e3-4654-4537-bb0a-536cdb71e6c0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.199548+05:30
ff05cba4-00ef-447c-9951-599670b1e645	5cea9442-f7f5-4645-a6e1-d6c07cf3d7cc	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.200884+05:30
9a7f6885-3085-4278-8f4a-1a9dc1720e48	098743d5-3182-42be-8583-3bf63600dad5	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.202336+05:30
81e8d63e-f803-4993-aef0-3ac7db9eb6e9	36bfc96e-4525-4334-856e-29c5d860fa6f	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.203582+05:30
b4e87c96-0020-47f1-92e1-54ba2df9da25	48327c47-deb2-4ef4-b275-25737d3d76b0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.204761+05:30
eda10ab9-1970-4542-a597-59a074c23a21	ed8011c9-45c1-4903-aa41-113c7e458beb	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.205845+05:30
28c0f89f-1ee4-4246-8a8b-3b5d5ad33962	88abd980-89b6-40ec-8ebb-d9a9d9422b18	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.206982+05:30
80ef9a3d-883a-4532-8345-452d9911d01d	9e02b430-e34f-4c82-82c2-04d53d22a960	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.208043+05:30
60f4f184-0e42-4b27-89ae-b288c1dcacbc	18735de2-a771-49db-9686-4397b02a6af2	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.209106+05:30
60ba1923-ed77-4ece-b9d1-6f110734b20d	6b852bd1-eff2-4956-b747-42c620f0f02a	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.210292+05:30
9c8b9487-1cd1-41c9-b6c2-e445cbadd042	e8c9c319-5361-4f0e-b8e4-7ca982bc98f6	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.211598+05:30
18bd3581-4ab6-434e-815b-e08b0b5ba695	f288544f-f19e-4e55-a378-625d0338ce61	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.212652+05:30
db133d0c-8bdc-4444-b6de-d1e31c8b45a8	dbb7011f-87f3-4a2d-b249-5a9624f65dc2	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.213673+05:30
76836015-f1b2-41f7-ade7-2839532fa130	34aa68c0-a9f2-4e9b-83ae-7541f8bee792	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.214884+05:30
65ed4f43-99c9-47d3-b0d1-eed65460a0a3	38c0d40c-dcf4-4c40-b14f-bf5b46d0082a	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.216046+05:30
68df8e5c-26df-401f-a7d4-95ba8b483d0b	ddeeab6d-a329-4dee-bfb0-73d382afe502	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.21707+05:30
ccc4aff4-ad55-4694-97a8-15165a7a0947	9145155a-9526-443c-81c5-7750d81335e7	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.218304+05:30
d7b2ee26-d0fd-4f67-990a-6dd5e3e66f36	9d995cc9-3b17-4ea0-9131-2c6e4c9bf773	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.219366+05:30
9ddfc942-0704-4c64-87c4-de33af77e4a2	e8c62684-beb0-464b-88e7-ae417c631c7a	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.220415+05:30
b41f534a-467f-406e-bb4f-fcf85b3248e4	9e3dd4ee-7228-4485-a261-ae267549ef24	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.221446+05:30
a547963c-5ae6-4124-9f38-4bb1459b2c66	17f12cdf-0049-4c0c-8141-99f18f8c1118	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.222474+05:30
d328870c-e287-4b79-8db7-2f9acba48afa	c547a060-58a8-4504-a867-5bc22f27e7a0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.223487+05:30
63d92fdb-98a7-4fc6-9a3f-65b06b8af0c1	58aa0f35-c04a-493c-a361-3f19d030e3e0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.224548+05:30
72aded08-2292-4bf0-b984-93db344eccd0	c6e53fa1-9ca4-4ab8-bbc0-7dfd111d82c1	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.225636+05:30
30de9c07-4d6a-4b5a-8a36-dc93df5d4788	315bc5c7-fa2a-4be2-86ed-9a7fbe55a206	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.226779+05:30
8932027d-0601-4bf7-84cc-afb5777cc8bd	878d59c7-668a-4371-9b19-a965ed77d8f6	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.227796+05:30
c4c88121-0536-426f-8572-a6b964071053	842e1060-813f-4d1d-b822-7a0b20a9cacd	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.228822+05:30
636032e2-0f6e-427e-990e-85aedfaa6830	2ebae7a5-7e53-4dfe-a647-c26da562290d	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.229943+05:30
58a49807-bfaa-4d61-9dce-ba49af4c1cc7	fdb4cfbb-1a94-419c-ba6f-70f67e654dbb	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.23129+05:30
25860de0-d35f-444d-839d-ab72e22335c3	bee6bff3-9e8c-43b4-97cd-e2faf4e2734b	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.232414+05:30
d6480c5d-7c9a-4eeb-b7a5-f88a255b37e8	30d0f8c4-5d64-4c2e-a88e-49b2162ed094	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.233501+05:30
920e9708-ca68-40f0-8083-e622bca7119a	577a6d08-8221-48cb-b30d-fba314d7f41c	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.234797+05:30
00ce0fa5-678a-4ae5-ae98-54e81e9d24ae	f92eb8f0-e4e1-4f79-95d7-f3a637866cd2	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.235832+05:30
a38c3058-a8e8-4c3b-8fbe-db222277f33d	0d5c4ec3-b54d-42b5-b3f9-7b8f093313d1	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.236871+05:30
1ef131dc-f5bc-4a95-9138-b101a061f26e	2b8c44f5-5f84-420c-bd7e-37776889265f	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.237904+05:30
40a1883b-172a-4919-ac73-83798f327ebc	80c5d80c-8f5d-4139-b204-5574860361c4	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.238935+05:30
c0bb2941-89de-43e8-968a-a63eceae9eb0	fc003678-4225-49b0-8da7-7992af652b65	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.239949+05:30
4216da97-56f8-4ba3-acbe-2584a310fb70	b5d73afb-366b-494a-a9e5-134ea910eeae	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.24097+05:30
2f40566a-bdc7-47ea-9c11-6558ffeb5709	ad317b78-f48b-4efb-8324-b7998c5defaf	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.242322+05:30
ca4ef7e9-44d0-4e9c-8006-31134dfdf238	9849c172-8884-4098-ba70-bdb4626ae49b	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.243372+05:30
0cbdb486-36e7-4703-918c-1dc0dcabbd08	334e4175-4191-4c3b-9f1c-3f12165cee4b	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.244428+05:30
2da4e46f-23b8-4643-b011-884b732240d7	2c04ea15-35e9-4183-a83f-195f61961289	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.245451+05:30
44c22a4d-cec9-4b3a-a762-f3c17e10e4dc	e4482828-549a-4020-a2fd-b49e41962141	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.246924+05:30
453d3130-300b-4f79-a183-f8b176005f7d	519a3703-aa59-48ae-9a7a-546dad7d3a38	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.247978+05:30
28f95524-7275-4f93-b6b7-8ac7e13255e1	b149b371-4dad-46c0-bc2b-54b232c4c5e0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.248996+05:30
9f2b7069-ef57-4bf1-ab79-6f8bedb79b9b	e00b0b29-4170-4cd3-9457-1516e25bf64d	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.25028+05:30
1c90b417-0726-41f4-a690-7478917ed717	d0f8a845-712b-40f3-8de4-c47c9bd80418	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.25136+05:30
b2078b21-90b7-434c-96e8-5dc328e13b88	5cda51eb-7d9e-4735-9d17-eef3a6623263	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.252538+05:30
37e5d329-39ca-4e7c-b320-bee828b77dcd	6abab44a-0b20-4452-98bf-594b40b16bcb	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.253697+05:30
c0aa4f3b-51d0-4fb3-b4a3-1a174c87c64e	5277ec0c-3cfe-4443-b76d-cf5d018e4fb0	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.254919+05:30
b2c5ccc9-8f3c-4c9d-b9bb-6ee7661ef89a	94d06b0f-3543-4af5-a3ac-e9e0315fc773	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.255955+05:30
65a14e37-5839-4fba-ba10-570927874d35	69f671e0-4acf-4cc7-a96b-f8abecbc164e	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.256988+05:30
8d75b401-9747-40c8-a741-b1fb1582bdb1	2a819d61-3166-4039-aeb4-158dfa2ef8a2	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.258284+05:30
5f861b7c-e447-48cc-b2a1-52c0cfe34205	666d0ae5-bd32-46e7-897a-77bacaa5e1ef	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.259346+05:30
69a261d8-e3bd-4df6-87b7-e7abb6104074	aeacd284-b7ee-4a62-968a-3c010fac4ef9	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.26037+05:30
656941ef-a7e3-4879-868d-0a15af8e0db3	50209c67-6054-4f98-9d2f-7e816ffb37b7	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.261422+05:30
5c184d8d-83fd-4964-a689-c6376969bc9d	f69adbf2-bff0-4e11-bc5d-709bf53e12a9	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.262511+05:30
5f12baf7-ce64-4899-a19e-6cdcb032b462	183f9aa0-99fc-427d-9030-c40c92b65e5f	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.263524+05:30
7276ad09-9698-4ea5-b5bc-d4a80433231a	e1a2aa52-52f0-4db1-a20c-f59ec0bc7159	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.264564+05:30
0f74bdeb-46df-4905-ad0f-5be6e11d19cf	79da19f3-57ef-43aa-af62-0a7a395d621c	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.265651+05:30
1187b9fb-0aaa-41a1-90c3-401503cf2f2f	b01ab36f-cae8-4090-b8a1-7bc00756b866	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.266784+05:30
0b7fbf7e-bb4a-490e-8b60-c309790ed1fc	f14eba03-1c94-4acb-96d1-dc803da93c87	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.267823+05:30
8621dfe9-a4ca-4d72-a26b-d6ff2e83e514	d6b2b4ea-2bb9-4d06-9207-fdad4146301a	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.268849+05:30
25926452-7898-48c9-920a-3e03a80c60a3	1ca8f4b6-236c-44f8-9288-e80a73b00987	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.269862+05:30
f3bc9450-3360-4293-944d-5e8c387fe0f4	feb72bbf-6795-4198-aa44-a1920643f4e9	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.270877+05:30
c43af4c1-532e-457e-91bf-44d5633a8f12	909fadd2-790d-4c53-a607-7e3462911f2b	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.272064+05:30
fda1d5de-e7bf-4015-a951-a15687f67f15	2c0e5a64-7033-4acc-bbe9-4a2f4f23d88d	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.273084+05:30
26dae868-2691-44db-add6-94a9fd3c7095	fabf729c-0541-4e6f-9f40-b5112a0a629c	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.274402+05:30
12059926-d670-4f64-af7b-f63442895988	c42dd346-c1e6-478b-8542-77012f6c51ec	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.275449+05:30
2cdd029d-b342-4f5d-affc-2a9a7c6b57fd	ae33e930-f3e0-4f78-8f06-4f89fc7e5494	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.276465+05:30
72f37e24-47f2-4468-a597-ef812e545ee2	75813e53-c91a-4a5b-b799-ffa94e11f5cb	\N	finding_detected	\N	open	{}	2026-10-10 04:27:25.277688+05:30
\.


--
-- TOC entry 5342 (class 0 OID 35176)
-- Dependencies: 243
-- Data for Name: finding_notes; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.finding_notes (id, finding_id, author_id, note, created_at) FROM stdin;
\.


--
-- TOC entry 5334 (class 0 OID 34541)
-- Dependencies: 234
-- Data for Name: findings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.findings (id, scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, status, ai_confidence, detected_at, resolved_at, created_at, updated_at, fingerprint, last_seen_at, assigned_to) FROM stdin;
b8d043f3-aae4-4240-8be3-4e4ef542f295	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.360632+05:30	\N	2026-10-10 04:26:57.360632+05:30	2026-10-10 04:26:57.360632+05:30	b8bc406d056c0318e16449efa7622ef314cc5461df894289bf97da384bc8586a	2026-10-10 04:26:57.360632+05:30	\N
496d9f8e-6530-4fa5-ab15-d3e877d1478e	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.362581+05:30	\N	2026-10-10 04:26:57.362581+05:30	2026-10-10 04:26:57.362581+05:30	1b7c665cb61c29c464fdd701c2225b7731b4601038e196c5609bc4e521018c52	2026-10-10 04:26:57.362581+05:30	\N
f45d70f7-bded-4b0d-a849-7b0bfc80be81	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.363783+05:30	\N	2026-10-10 04:26:57.363783+05:30	2026-10-10 04:26:57.363783+05:30	658689c115eeb4846b6463f7b91d3be754939e3ca97dc302e038c1fef0efd8c5	2026-10-10 04:26:57.363783+05:30	\N
7488c3a3-e600-4749-920d-cedb48aca500	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/favicon.ico	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.364964+05:30	\N	2026-10-10 04:26:57.364964+05:30	2026-10-10 04:26:57.364964+05:30	51660ce42b2478e689de50231bab6c78cb82b9ba55d0c2fa48e19db02033ddf3	2026-10-10 04:26:57.364964+05:30	\N
b19c7bd9-fbcf-4ca7-92b5-34d1d11db3d4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.366076+05:30	\N	2026-10-10 04:26:57.366076+05:30	2026-10-10 04:26:57.366076+05:30	7ff509a1bb13df15e74348cb490de9caa927cd3905ffc7f7ed22da00b7dff801	2026-10-10 04:26:57.366076+05:30	\N
8e2ac041-12e7-47ff-be70-b90d8b9f5028	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/favicon.png	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.367182+05:30	\N	2026-10-10 04:26:57.367182+05:30	2026-10-10 04:26:57.367182+05:30	53b21d68453123b22ae97971275e7f95fa20e30f0208a0ea3a9be79048d78d0c	2026-10-10 04:26:57.367182+05:30	\N
3d84f41a-b4ec-4f94-a194-27c022a68346	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.368285+05:30	\N	2026-10-10 04:26:57.368285+05:30	2026-10-10 04:26:57.368285+05:30	ac425dffc86bdfc47e883b61a88ae1a3f41eec1f04160af8f48c58f3f32f4c13	2026-10-10 04:26:57.368285+05:30	\N
616f718b-3ad4-4039-be69-cfa4514d9de8	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/css/output.css	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.369303+05:30	\N	2026-10-10 04:26:57.369303+05:30	2026-10-10 04:26:57.369303+05:30	68f1968b2d0271f81bb64d30d69157df45cb30ec9be887e84c4a16e9ee57215e	2026-10-10 04:26:57.369303+05:30	\N
c612a004-a36f-4043-aadf-95af54382cb6	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.370336+05:30	\N	2026-10-10 04:26:57.370336+05:30	2026-10-10 04:26:57.370336+05:30	d94e1d1c60ed534d8bab883de910ae9ca789c308f46ffe4adfdcd981f5552b9b	2026-10-10 04:26:57.370336+05:30	\N
447ff835-53cb-4694-89bf-ead0384c1ed4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/css/aos.css	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.371362+05:30	\N	2026-10-10 04:26:57.371362+05:30	2026-10-10 04:26:57.371362+05:30	eaa145ba97f97ba1bb988a061013773c53302044696c08eb03ac901fea86b1f3	2026-10-10 04:26:57.371362+05:30	\N
b46539e8-1066-4449-b9ae-48ffbdd06b79	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.372376+05:30	\N	2026-10-10 04:26:57.372376+05:30	2026-10-10 04:26:57.372376+05:30	3bd906a8404cdfbccf8c2e3eedfd086b2b814f55972ff3116601d5ccdd54acf1	2026-10-10 04:26:57.372376+05:30	\N
a771c95f-fc0d-4ccf-802a-a70e31d5edd7	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.373523+05:30	\N	2026-10-10 04:26:57.373523+05:30	2026-10-10 04:26:57.373523+05:30	b09c836545a6c6ae8b7ae84fdf38ca609bad718e5e213fb96e91298d4916fcbb	2026-10-10 04:26:57.373523+05:30	\N
34aa68c0-a9f2-4e9b-83ae-7541f8bee792	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.214456+05:30	\N	2026-10-10 04:27:25.214456+05:30	2026-10-10 04:27:25.214456+05:30	57cb0d804a222ebec04ca9778d0dd140215d8ba3978cd22d04477474b5303c6f	2026-10-10 04:27:25.214456+05:30	\N
181bfa33-442a-4432-bfa5-ec1d223d0cbd	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.37466+05:30	\N	2026-10-10 04:26:57.37466+05:30	2026-10-10 04:26:57.37466+05:30	f0f3f01f5d6e5da3e1c04c4fb5f35a08dc414a250c4fcf7fc8835ac9b76264c7	2026-10-10 04:26:57.37466+05:30	\N
c32d993a-5131-4922-8ad0-18063c8f4706	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.375926+05:30	\N	2026-10-10 04:26:57.375926+05:30	2026-10-10 04:26:57.375926+05:30	167ea9f755d303ab23bf3271f8327e4e0e57b49a87835d6da1721caa661f44fb	2026-10-10 04:26:57.375926+05:30	\N
3d745fa0-151e-4151-b3be-bcdac0e8925d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.376967+05:30	\N	2026-10-10 04:26:57.376967+05:30	2026-10-10 04:26:57.376967+05:30	0b0adca97181bf0e07c2306122f323a4c974d4c10ca61987e96eb5265686e623	2026-10-10 04:26:57.376967+05:30	\N
df827556-3586-4199-889a-f9b41b84d6fe	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.378028+05:30	\N	2026-10-10 04:26:57.378028+05:30	2026-10-10 04:26:57.378028+05:30	1a73215c5c7ee8d30f6098ea6bf9ba8344f3ddf9850a961210db16372a4eec0f	2026-10-10 04:26:57.378028+05:30	\N
5dbf7b21-558e-4d43-9170-a960c3d13d53	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.379043+05:30	\N	2026-10-10 04:26:57.379043+05:30	2026-10-10 04:26:57.379043+05:30	9b3a1f1ea2084760e0c2543fd4d7ec6ebce0e801ecb55d4fdc03cba3a5de6578	2026-10-10 04:26:57.379043+05:30	\N
a59afd72-a35b-4a06-87a0-4fd77748e85c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.380059+05:30	\N	2026-10-10 04:26:57.380059+05:30	2026-10-10 04:26:57.380059+05:30	e0700446d53c8f3fc078ea04165b57340b18aee79ab6af14d7716b49cb3e2304	2026-10-10 04:26:57.380059+05:30	\N
8c5d71fa-9162-4d9f-acde-7d69fe8fb738	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.381072+05:30	\N	2026-10-10 04:26:57.381072+05:30	2026-10-10 04:26:57.381072+05:30	e38dd31aa02992111f259364bb071dce03e7004f366f78cea97982e68c9a0e3e	2026-10-10 04:26:57.381072+05:30	\N
c5ad22f5-0ab6-4637-bcf3-7446dd1c2f8d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.382102+05:30	\N	2026-10-10 04:26:57.382102+05:30	2026-10-10 04:26:57.382102+05:30	7ac78f86c75da89f46be53a5e8960cbf7ef2d00e3244d68df4ffee3c839b02ac	2026-10-10 04:26:57.382102+05:30	\N
7ccc41d0-130b-4920-99db-f7e49ae54957	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.383114+05:30	\N	2026-10-10 04:26:57.383114+05:30	2026-10-10 04:26:57.383114+05:30	99e91151b674785d523db1cdf16787dc7bbfc28f88a9e43fde932c4797c96a25	2026-10-10 04:26:57.383114+05:30	\N
6a18a2aa-4c56-4946-9a63-f34c1c6b3cd4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.384262+05:30	\N	2026-10-10 04:26:57.384262+05:30	2026-10-10 04:26:57.384262+05:30	68634c7a4f60d8dc06161b17a6b03b92ee34f3404ad5ff250df9639c557a35fe	2026-10-10 04:26:57.384262+05:30	\N
adf12a6e-a55f-4fb0-a21f-19515c3189d6	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.385363+05:30	\N	2026-10-10 04:26:57.385363+05:30	2026-10-10 04:26:57.385363+05:30	134f35464c2fa69101d9b155fbef8ad4e543530e15fc7802871c5fc0e2acec60	2026-10-10 04:26:57.385363+05:30	\N
21378f17-7b0b-49a0-a11b-3b673c0a1766	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.386447+05:30	\N	2026-10-10 04:26:57.386447+05:30	2026-10-10 04:26:57.386447+05:30	aebf255cacaf258445c65127e3bdc81b890ba49c3e33cd54dce5cb4e033fae01	2026-10-10 04:26:57.386447+05:30	\N
cce9f62d-831c-4b5f-8ebb-1437ca65dd61	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.387488+05:30	\N	2026-10-10 04:26:57.387488+05:30	2026-10-10 04:26:57.387488+05:30	9d44369d96101c284c550b7c60d91854bf164bc0d1e93d6dfdf25ad799a23660	2026-10-10 04:26:57.387488+05:30	\N
0c03cbd5-18e7-4d13-8aeb-d9a1b926f956	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.38871+05:30	\N	2026-10-10 04:26:57.38871+05:30	2026-10-10 04:26:57.38871+05:30	6de0d6fc4fa61ecbf0218b5c0287de7261b1f321b9b861e249c1b3d5b1195483	2026-10-10 04:26:57.38871+05:30	\N
409143ca-b56f-4792-a277-352f8b5b0a2c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.389782+05:30	\N	2026-10-10 04:26:57.389782+05:30	2026-10-10 04:26:57.389782+05:30	2907edfee5bdff8682f1a8f24dd12b13230122649c06a9cab1ddebe4e342a17a	2026-10-10 04:26:57.389782+05:30	\N
0ded09fe-a1f7-44f8-8013-1ad04cc1e42a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/faq.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.390845+05:30	\N	2026-10-10 04:26:57.390845+05:30	2026-10-10 04:26:57.390845+05:30	34dc94b113a776baffda899b5b6571093de17f29f828cef83b5bbd4bcee09434	2026-10-10 04:26:57.390845+05:30	\N
445ea95a-7c60-4f8a-abe4-ff95f44c9d52	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/about.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.391874+05:30	\N	2026-10-10 04:26:57.391874+05:30	2026-10-10 04:26:57.391874+05:30	184d6480075a8ebd6684ec3f29ed5b4b182ce51aa19cd68711e438af66c5563a	2026-10-10 04:26:57.391874+05:30	\N
572606cb-5bc3-4bed-8dd7-fa305f905173	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/about.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.392904+05:30	\N	2026-10-10 04:26:57.392904+05:30	2026-10-10 04:26:57.392904+05:30	2b110c5a06a9331b1e1ffeab6ebbf42139e01790e6ba9058a7da5ef9ea689084	2026-10-10 04:26:57.392904+05:30	\N
ba3b4c09-872f-4f09-a163-b186f9d389e5	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.393934+05:30	\N	2026-10-10 04:26:57.393934+05:30	2026-10-10 04:26:57.393934+05:30	7a5527966e4997157e01b847d02c4a840008c335b889333733e882885ce4a51e	2026-10-10 04:26:57.393934+05:30	\N
0d86fae6-644c-4045-bd82-a902dca990c1	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.395006+05:30	\N	2026-10-10 04:26:57.395006+05:30	2026-10-10 04:26:57.395006+05:30	ada025456cd65e7c139227d5bef6a13fd1deeff2288d9f09984c9f759f2842ec	2026-10-10 04:26:57.395006+05:30	\N
c831dbd3-e217-4bad-9691-dc5a6e77f98b	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_misconfiguration	Missing HttpOnly Cookie Attribute: PHPSESSID	A cookie lacks the 'HttpOnly' attribute, making it accessible to client-side JavaScript and increasing the impact of potential XSS attacks.	low	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Ensure the 'HttpOnly' flag is set for session and authentication cookies.	open	1.000	2026-10-10 04:26:57.396039+05:30	\N	2026-10-10 04:26:57.396039+05:30	2026-10-10 04:26:57.396039+05:30	63ec4bf8a896e0eaba1ceda346b3c5ba4f1cf0eef35ffba969f64a43656a82dd	2026-10-10 04:26:57.396039+05:30	\N
6dae9427-2013-428e-b54a-42d80e64a463	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_misconfiguration	Missing SameSite Cookie Attribute: PHPSESSID	A cookie lacks the 'SameSite' attribute, which removes a layer of defense against Cross-Site Request Forgery (CSRF).	info	\N	\N	https://thephotopunditz.com/contact.php	\N	{"cookie_name": "PHPSESSID"}	Configure the 'SameSite' attribute to 'Lax' or 'Strict' depending on cross-domain requirements.	open	1.000	2026-10-10 04:26:57.397061+05:30	\N	2026-10-10 04:26:57.397061+05:30	2026-10-10 04:26:57.397061+05:30	a7f85d299e335b6035d6ae966c2f2e705ab11e9dbccc657b30308a58c3da9d3e	2026-10-10 04:26:57.397061+05:30	\N
73758529-cdcd-4e3a-bad4-1715ebe52b3b	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.39811+05:30	\N	2026-10-10 04:26:57.39811+05:30	2026-10-10 04:26:57.39811+05:30	636a72cbb3b634d2b6a480f1f865c07395e3a59e70e727542f06d27677033eba	2026-10-10 04:26:57.39811+05:30	\N
f4ef0464-6cc5-421b-a639-81e50b747bfd	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.399138+05:30	\N	2026-10-10 04:26:57.399138+05:30	2026-10-10 04:26:57.399138+05:30	42fbfc794cd3f76a66c20e6f1705bdd623fa92a57334fa44f48effc4a0288935	2026-10-10 04:26:57.399138+05:30	\N
f04abc96-e47a-4617-8fcf-402de8969b48	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.400169+05:30	\N	2026-10-10 04:26:57.400169+05:30	2026-10-10 04:26:57.400169+05:30	24727e748b264442d65356ac02fbc837553879307cbf790d08fc211fc9d613d7	2026-10-10 04:26:57.400169+05:30	\N
cde34241-a190-43bb-8fb5-9688f7a5440f	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/js/aos.js	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.401189+05:30	\N	2026-10-10 04:26:57.401189+05:30	2026-10-10 04:26:57.401189+05:30	63441a68161a81b57e0e025634de2378995667b0e8bc30b26130d9c45bab3bf8	2026-10-10 04:26:57.401189+05:30	\N
951626e3-df41-431e-b5c6-876b59295264	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/fallback;	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.402256+05:30	\N	2026-10-10 04:26:57.402256+05:30	2026-10-10 04:26:57.402256+05:30	45c736b46ea7f843d4de01ace6fc1b13d7ef7414c220a7399d6e85007f326def	2026-10-10 04:26:57.402256+05:30	\N
29b23ed1-7359-4871-9676-2cc8c6133871	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/fallback;	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.403588+05:30	\N	2026-10-10 04:26:57.403588+05:30	2026-10-10 04:26:57.403588+05:30	011a875ad6b7688de1bb446636a97876b31d7ce469586ca745b8b05ff7299e3e	2026-10-10 04:26:57.403588+05:30	\N
ed3e69dd-0311-4dd4-8669-b5177eca28aa	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/featsBg.find(img	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.405498+05:30	\N	2026-10-10 04:26:57.405498+05:30	2026-10-10 04:26:57.405498+05:30	4875cb9c66a993b10dde88983f8a505f53dc1598e96df57506b270a4be469106	2026-10-10 04:26:57.405498+05:30	\N
b20f42cc-c314-42c0-a737-83c5448787ed	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/featsBg.find(img	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.406664+05:30	\N	2026-10-10 04:26:57.406664+05:30	2026-10-10 04:26:57.406664+05:30	c9a50c558bf6d0f22adbfa56e1617881c9139db83f2771df30ac685b6ac3a9d8	2026-10-10 04:26:57.406664+05:30	\N
b3b354ec-3857-42e8-9d7a-37b1ec4bd25e	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.407727+05:30	\N	2026-10-10 04:26:57.407727+05:30	2026-10-10 04:26:57.407727+05:30	1f5ad03752cca5965e51bdfb597a99b90bc5c93df108cf0a2c9a71fb91cc1d6c	2026-10-10 04:26:57.407727+05:30	\N
22c9d0fc-96c3-4aab-acb4-c8c65624ad6a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7Btest.img%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.408768+05:30	\N	2026-10-10 04:26:57.408768+05:30	2026-10-10 04:26:57.408768+05:30	881e220b78320f854a01f2f0f5b132052a96f2447b6c67d6068feb021253d822	2026-10-10 04:26:57.408768+05:30	\N
50129f4b-eb24-48d4-b49e-2b797b29a65a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.409795+05:30	\N	2026-10-10 04:26:57.409795+05:30	2026-10-10 04:26:57.409795+05:30	09ed76e7855e03539a6faa51ab4b3218e30d379084cfce32517e3788c2a9b35d	2026-10-10 04:26:57.409795+05:30	\N
39a8a76a-b172-4b0b-a3c9-21f11e2cd864	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.410819+05:30	\N	2026-10-10 04:26:57.410819+05:30	2026-10-10 04:26:57.410819+05:30	9877afe1abc5bcf28c74ddb26211061d703adf08e0288e52f3bebc59a4937099	2026-10-10 04:26:57.410819+05:30	\N
a8c73430-4197-4b94-82e8-57ce435685dc	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.411852+05:30	\N	2026-10-10 04:26:57.411852+05:30	2026-10-10 04:26:57.411852+05:30	0bf09dbaa2c362b7198791a61b7bdbb014cdaa11e1b09311ef977035ce555d37	2026-10-10 04:26:57.411852+05:30	\N
94daa859-5c59-4be3-8f2b-a2ef48fc703d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/aayushi---raahat.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.412897+05:30	\N	2026-10-10 04:26:57.412897+05:30	2026-10-10 04:26:57.412897+05:30	34780ed6c1d02bae8c0fe759f2d81f8c63e6c62092d248ff66f93e3799bfac4f	2026-10-10 04:26:57.412897+05:30	\N
0c550814-d628-4f9d-a793-373fb42c2ac7	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.41392+05:30	\N	2026-10-10 04:26:57.41392+05:30	2026-10-10 04:26:57.41392+05:30	180f4d62b34258f300952330606e863eee80ec7299da1138263a249b4af73c2f	2026-10-10 04:26:57.41392+05:30	\N
fdb4cfbb-1a94-419c-ba6f-70f67e654dbb	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/loya	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.230842+05:30	\N	2026-10-10 04:27:25.230842+05:30	2026-10-10 04:27:25.230842+05:30	3c11ac6caa572fec586ccc712758ac287daa3e85f2d5373bf3d00d93f5101c2c	2026-10-10 04:27:25.230842+05:30	\N
06e0dfa1-6cf8-4568-a4a8-74c1fd9dbf1d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/bride.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.415033+05:30	\N	2026-10-10 04:26:57.415033+05:30	2026-10-10 04:26:57.415033+05:30	43eaa9c9b8803e580803d1ae352412a5f93c663d023ebc84555ff1382c39d110	2026-10-10 04:26:57.415033+05:30	\N
799be6a6-5694-484d-8ed4-5ae4d50ccf10	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.416158+05:30	\N	2026-10-10 04:26:57.416158+05:30	2026-10-10 04:26:57.416158+05:30	1e68bc63796b3137ee5fa7bb10ad6570328533716b3e9c111ad82f5d79979d86	2026-10-10 04:26:57.416158+05:30	\N
c8ed774f-ecf0-4a01-a6c6-d9677d534c29	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/chadani---chirag.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.417179+05:30	\N	2026-10-10 04:26:57.417179+05:30	2026-10-10 04:26:57.417179+05:30	1df0b2eaeb26ae3d7c212be6de5fe660d230485cd7ff687ca3ba2cfb1b2ba256	2026-10-10 04:26:57.417179+05:30	\N
e0f56ee9-b567-41bc-b553-ba4c64993537	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.418246+05:30	\N	2026-10-10 04:26:57.418246+05:30	2026-10-10 04:26:57.418246+05:30	6d7dc9b7a429cf63a6d18f224ce42c2f3207dde65a484d498ebe52f6aaf362e2	2026-10-10 04:26:57.418246+05:30	\N
1599933f-33f2-42b9-8e51-2d3824d66c5c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/j---p.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.419265+05:30	\N	2026-10-10 04:26:57.419265+05:30	2026-10-10 04:26:57.419265+05:30	55a265b195eebb1ddfbea7484fe89c62fa18b7a73e8f1b80b30b6dd0b3d56aae	2026-10-10 04:26:57.419265+05:30	\N
40ec776e-3613-4eb1-9b9e-548ea78fc14c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.420539+05:30	\N	2026-10-10 04:26:57.420539+05:30	2026-10-10 04:26:57.420539+05:30	4985b78fba0637ea1a8075f4b1a5ded8fea6f96e3ffa8aea30149e3f86dec175	2026-10-10 04:26:57.420539+05:30	\N
b3fac1b7-f7f1-4900-8bf4-1bbd60abdb42	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/megha---ankit.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.421633+05:30	\N	2026-10-10 04:26:57.421633+05:30	2026-10-10 04:26:57.421633+05:30	94d7907eb2f0a8620e11b100e99d68627834cc64fdec981655375cbe354e7e36	2026-10-10 04:26:57.421633+05:30	\N
7580179f-8285-482c-a490-2a0d73af5960	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.422661+05:30	\N	2026-10-10 04:26:57.422661+05:30	2026-10-10 04:26:57.422661+05:30	4442ac90183e6b23507f2714e5667a46d894e7baa6881e1bb66ccb6da477a2e3	2026-10-10 04:26:57.422661+05:30	\N
b6d39b21-3260-482a-a5e7-bcd702c198ca	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/neel---mike.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.423687+05:30	\N	2026-10-10 04:26:57.423687+05:30	2026-10-10 04:26:57.423687+05:30	de05b012f5ce4dbef7fc692f047e01f0e8e85bff3168d813cdce8bca9c3d4ae5	2026-10-10 04:26:57.423687+05:30	\N
f85d6b93-4180-406a-a8a2-5741e327e56c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.424746+05:30	\N	2026-10-10 04:26:57.424746+05:30	2026-10-10 04:26:57.424746+05:30	bc59c4456914f7b5312f5070e48b2ff778ae6cfaff03ab121eb8bfedc5ddc7f1	2026-10-10 04:26:57.424746+05:30	\N
13eb097f-ad5d-4bb8-a88d-55cb19187490	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/nikaah.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.425766+05:30	\N	2026-10-10 04:26:57.425766+05:30	2026-10-10 04:26:57.425766+05:30	1ac276487cdbbed7e7a8cda76a3011b747eb658d7e17ed4efe910317fec51c5d	2026-10-10 04:26:57.425766+05:30	\N
10532726-9715-4350-9981-9654e3c5f010	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.42682+05:30	\N	2026-10-10 04:26:57.42682+05:30	2026-10-10 04:26:57.42682+05:30	2a3a5c16fffe05e035949f025461ce4ac486291fec9ea36f5e51519c346e1bad	2026-10-10 04:26:57.42682+05:30	\N
a59cb1e3-aea7-46bc-9dbf-2d748d9b8f3c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/ninad---rupali.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.427868+05:30	\N	2026-10-10 04:26:57.427868+05:30	2026-10-10 04:26:57.427868+05:30	d103e033985a21a05a367388a1ab063e6a742b0a738bf3713403f73eaa89be7d	2026-10-10 04:26:57.427868+05:30	\N
d3313ee6-8ee3-4277-bac0-8e902a13d736	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.428922+05:30	\N	2026-10-10 04:26:57.428922+05:30	2026-10-10 04:26:57.428922+05:30	f631f9eef97e94438dc76705b88a5057dfe6ffba33f5a2b2f9bda257a5881c09	2026-10-10 04:26:57.428922+05:30	\N
90d227a6-da3a-4e0a-9ae1-70cf499b0d4c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/prerita---bhairav.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.429954+05:30	\N	2026-10-10 04:26:57.429954+05:30	2026-10-10 04:26:57.429954+05:30	f9551d69f80bb196ed5054138cddad77c47c6ca8c928b1a259e8908845cfd72c	2026-10-10 04:26:57.429954+05:30	\N
14f5df17-6f03-45b0-b5af-707380e0461c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.430972+05:30	\N	2026-10-10 04:26:57.430972+05:30	2026-10-10 04:26:57.430972+05:30	0c115fafe42059940f67b55fb4bb6318c2cd148f07e0f30a0b512b8fc6e8226d	2026-10-10 04:26:57.430972+05:30	\N
47f30541-3237-4138-a3be-02a5cbecb3cf	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/r---o.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.431986+05:30	\N	2026-10-10 04:26:57.431986+05:30	2026-10-10 04:26:57.431986+05:30	0f1183cf6a057f7c0ef72e6601e91c0e8f10b1389057709a512eadba29b98808	2026-10-10 04:26:57.431986+05:30	\N
d1995312-c44a-4412-aff1-49c996a613f0	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.433006+05:30	\N	2026-10-10 04:26:57.433006+05:30	2026-10-10 04:26:57.433006+05:30	566c822277591dd4e1d1eed8045dfbbe71e724f59ea936c2806ecd1a522f7eb9	2026-10-10 04:26:57.433006+05:30	\N
ce0a86ab-3dfb-44d5-9f58-a57a2ccc1f88	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/s---a.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.434047+05:30	\N	2026-10-10 04:26:57.434047+05:30	2026-10-10 04:26:57.434047+05:30	10cc9f49d641ff5e4bd0d73e2296989c978e13e242ce8acb21d2dc8afc0d9b6f	2026-10-10 04:26:57.434047+05:30	\N
546500ac-a315-4726-8a82-0110b630cc15	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.435076+05:30	\N	2026-10-10 04:26:57.435076+05:30	2026-10-10 04:26:57.435076+05:30	6a86e09792ecae20dd3841c474c981bfb5bb66ead71cbca5fb39c44a0944ce26	2026-10-10 04:26:57.435076+05:30	\N
b6a40db9-d4ff-4879-9285-2281fb328dde	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/wedding-highlights.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.436395+05:30	\N	2026-10-10 04:26:57.436395+05:30	2026-10-10 04:26:57.436395+05:30	79d8ad1ffb33066bf9b562fbd0cadb4adb14a39236fdeaf75db52bd2810a4c48	2026-10-10 04:26:57.436395+05:30	\N
f814b01d-24c6-4eb5-b6d9-cba7b8a83802	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.437535+05:30	\N	2026-10-10 04:26:57.437535+05:30	2026-10-10 04:26:57.437535+05:30	86443cec26b4f30ce07ab1eedf8d00eff89aa8b88da4240c8d056b6ffe25c5f1	2026-10-10 04:26:57.437535+05:30	\N
6850f576-9f36-4f8d-b265-89c6eeee5568	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7Bfallback%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.438574+05:30	\N	2026-10-10 04:26:57.438574+05:30	2026-10-10 04:26:57.438574+05:30	126f3ff02dab265072b6cc70c7f0b1ab9f03a0b32141c744d83782cbb2b333b5	2026-10-10 04:26:57.438574+05:30	\N
57bb8925-fea6-4cd0-94bf-c89804308829	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.439607+05:30	\N	2026-10-10 04:26:57.439607+05:30	2026-10-10 04:26:57.439607+05:30	3c48529db7093613b5c5374c3fad5af90efa9b323a09f3c804ca5d9d6536d7b9	2026-10-10 04:26:57.439607+05:30	\N
f5a869c0-d4ee-4967-a8b5-df57e62122f4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7BlinkUrl%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.440634+05:30	\N	2026-10-10 04:26:57.440634+05:30	2026-10-10 04:26:57.440634+05:30	3dc542ee481dffc7541ec94d73fa40bbe17f46e71564fd75a393b855166db025	2026-10-10 04:26:57.440634+05:30	\N
22792de0-c1d3-4418-b3c6-c4b03e7c9e63	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.441696+05:30	\N	2026-10-10 04:26:57.441696+05:30	2026-10-10 04:26:57.441696+05:30	8b9d2ca004f343e3a2ace144a36f075ea2e14289b480b3e640c87585d2252246	2026-10-10 04:26:57.441696+05:30	\N
a3b9b8be-a199-4aa2-af3d-0cd0afe06dea	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7BfallbackImg%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.442723+05:30	\N	2026-10-10 04:26:57.442723+05:30	2026-10-10 04:26:57.442723+05:30	6329e6a7cd2b066a86ff60482cdcd728e01e0572b5b3e5008e5fa63b38384ce2	2026-10-10 04:26:57.442723+05:30	\N
e1ff06e7-558f-4972-83c1-317d730568d1	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.443757+05:30	\N	2026-10-10 04:26:57.443757+05:30	2026-10-10 04:26:57.443757+05:30	27e9de88215b2e1e498040f8b790d5c11b1273d6202bf10615a90d354cd85f0e	2026-10-10 04:26:57.443757+05:30	\N
0e1bd6b8-0f3d-4412-805a-e1b64fb12d20	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.444901+05:30	\N	2026-10-10 04:26:57.444901+05:30	2026-10-10 04:26:57.444901+05:30	c0659f6416b4be8de15872a4852278c23a21875f309d53d32e7038b6108932a1	2026-10-10 04:26:57.444901+05:30	\N
7fcba045-b6dd-470c-b97f-3dc863e0e93d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.445983+05:30	\N	2026-10-10 04:26:57.445983+05:30	2026-10-10 04:26:57.445983+05:30	6bf44cf7f35828e265f1b6d412bb3a0c9d6db65a404dd7d5b681aca0bc6edc94	2026-10-10 04:26:57.445983+05:30	\N
35c7865c-fdde-4e89-b013-c6defe846304	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.447024+05:30	\N	2026-10-10 04:26:57.447024+05:30	2026-10-10 04:26:57.447024+05:30	c7d67f2988870bdbf9dea5e617366b29b4ffcbaba0f4020da95f2f83256ff16a	2026-10-10 04:26:57.447024+05:30	\N
88523cba-2a30-4fe2-8b65-bc271a987001	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.448099+05:30	\N	2026-10-10 04:26:57.448099+05:30	2026-10-10 04:26:57.448099+05:30	3481209011f0bf46709ec8b4555289520b458999d4fb55ba0ac5908f8b488e01	2026-10-10 04:26:57.448099+05:30	\N
87bb6c9b-26cf-4c56-affd-86a960e59335	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.449138+05:30	\N	2026-10-10 04:26:57.449138+05:30	2026-10-10 04:26:57.449138+05:30	5e41ab4ce8ecc8135e2dd4403a3878719b9b489c82933bebdaa12ec8c1d1c479	2026-10-10 04:26:57.449138+05:30	\N
62cb59ff-f279-4176-8035-38277607cf49	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.450446+05:30	\N	2026-10-10 04:26:57.450446+05:30	2026-10-10 04:26:57.450446+05:30	4c8bf7d939fda534fbb8533a688fb4ede33cb8ca73c2ba0c6805349b5128cb52	2026-10-10 04:26:57.450446+05:30	\N
bef5bf62-edba-4d75-a626-21d977f23993	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.451629+05:30	\N	2026-10-10 04:26:57.451629+05:30	2026-10-10 04:26:57.451629+05:30	ba5a1a76d0ab2cba9df7dffa502fe6253644622dad58c219ca6040cdf59055d0	2026-10-10 04:26:57.451629+05:30	\N
38f9b028-2dda-4b79-b4b3-b4031ea1186b	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.452658+05:30	\N	2026-10-10 04:26:57.452658+05:30	2026-10-10 04:26:57.452658+05:30	c1bed7e1b5bfd10c5ab7b1a0a747e1c4651f0965f756b753b002f287886bdf71	2026-10-10 04:26:57.452658+05:30	\N
bb84e75a-6385-470b-abcb-f2124e542e14	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.453707+05:30	\N	2026-10-10 04:26:57.453707+05:30	2026-10-10 04:26:57.453707+05:30	cc3c4fe5508d2d050890fe5534954ffa3028e5ce70e28ccda3dba645fd90cd4f	2026-10-10 04:26:57.453707+05:30	\N
0b6dab97-c40d-4f21-9bb6-701361d4c363	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.45478+05:30	\N	2026-10-10 04:26:57.45478+05:30	2026-10-10 04:26:57.45478+05:30	05ad8695561e2b77df1c50e5e2bea8884070df5647676c2507c02a1c70e27f5f	2026-10-10 04:26:57.45478+05:30	\N
d71e80b0-6e35-47d7-bcf9-8eeed19f3e2a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.455814+05:30	\N	2026-10-10 04:26:57.455814+05:30	2026-10-10 04:26:57.455814+05:30	4311bd93ab45b0195f3ddd18ad1790c21a0c37435a6ff4b45133d4bcb06ccf18	2026-10-10 04:26:57.455814+05:30	\N
cbc7ebee-9185-443b-935e-13d53a4ba4eb	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.456829+05:30	\N	2026-10-10 04:26:57.456829+05:30	2026-10-10 04:26:57.456829+05:30	dd948607b15534a67ae05d9718d9e65717965cbba496840015edbe3e637e65b5	2026-10-10 04:26:57.456829+05:30	\N
0e807a94-3931-4101-b25b-a202aec5ae93	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.457884+05:30	\N	2026-10-10 04:26:57.457884+05:30	2026-10-10 04:26:57.457884+05:30	38a175bd396870d188030412353748aeb84f6d215c114e00492ef9c24875f0c3	2026-10-10 04:26:57.457884+05:30	\N
a625f0c4-5b5e-4a50-ab9a-6e733eb50f02	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.458898+05:30	\N	2026-10-10 04:26:57.458898+05:30	2026-10-10 04:26:57.458898+05:30	ef7491a7f175e07b22fb509cc793585190a914aeb4c1d3ba3c091490be5cd499	2026-10-10 04:26:57.458898+05:30	\N
7551b5fc-3351-4551-bb9f-61416118448a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7BthumbnailFallback%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.459954+05:30	\N	2026-10-10 04:26:57.459954+05:30	2026-10-10 04:26:57.459954+05:30	272be524b807d04ebad9d852157b87083a185fdc6f646b4ba624927480af4780	2026-10-10 04:26:57.459954+05:30	\N
12ad24af-31c2-4cd7-bcb5-6864c8caca33	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.460975+05:30	\N	2026-10-10 04:26:57.460975+05:30	2026-10-10 04:26:57.460975+05:30	adf5cafcaf32bb12a7c43920dba07a4bdabfd5ab40458b09fb253c63ad4db718	2026-10-10 04:26:57.460975+05:30	\N
d8dc483d-e872-44e8-8cd4-8e8c8e8e9b8c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.461993+05:30	\N	2026-10-10 04:26:57.461993+05:30	2026-10-10 04:26:57.461993+05:30	5e02a18aae93c630b76df6aaf7fea5af835a451f31668a9b45ce4c4986d6a2b0	2026-10-10 04:26:57.461993+05:30	\N
10b254eb-113b-4781-a730-a022bafbfe67	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.463016+05:30	\N	2026-10-10 04:26:57.463016+05:30	2026-10-10 04:26:57.463016+05:30	b5d966f84aa53b82fa1903514d7de6d71433eeb71c7c294d3eb0af4d845e86b2	2026-10-10 04:26:57.463016+05:30	\N
a4ec68a2-54c4-4e11-b2ef-dfc4a5454090	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.464046+05:30	\N	2026-10-10 04:26:57.464046+05:30	2026-10-10 04:26:57.464046+05:30	7e3e1959cc4423ecaacee768ecf6572beedd39f04fdb43c4afd7199e4b92c9e1	2026-10-10 04:26:57.464046+05:30	\N
41a6a9e8-ac54-4042-84ab-c98be35f0680	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.465106+05:30	\N	2026-10-10 04:26:57.465106+05:30	2026-10-10 04:26:57.465106+05:30	c0265b53423dbf162c7e8e89cd99ff683cce720246eae34a5e93c4ba7fb5d157	2026-10-10 04:26:57.465106+05:30	\N
22b99716-dcfb-47f2-bc07-d2180736218a	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.466153+05:30	\N	2026-10-10 04:26:57.466153+05:30	2026-10-10 04:26:57.466153+05:30	253025e018f70bb58965c42257601a95016900bb364bab4eb00cffc39f2657f5	2026-10-10 04:26:57.466153+05:30	\N
95df6188-5ffa-46b4-a8e7-334d057a8043	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.467546+05:30	\N	2026-10-10 04:26:57.467546+05:30	2026-10-10 04:26:57.467546+05:30	b6b26b5ca4fd74d0a6ace9b17382dc8f866d3bc60af258992d0682a861c82974	2026-10-10 04:26:57.467546+05:30	\N
a2b3521b-d3d8-47fe-9f28-97a2e6412bc4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7Bsrc%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.4686+05:30	\N	2026-10-10 04:26:57.4686+05:30	2026-10-10 04:26:57.4686+05:30	37cb8138a1934fd64cae3368e244b7aa012c75631d34ae4bd26f7646b2abf3cf	2026-10-10 04:26:57.4686+05:30	\N
f2a25f2a-910d-47f1-8ae2-e71e1b4cf5de	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/defaultImage;	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.469635+05:30	\N	2026-10-10 04:26:57.469635+05:30	2026-10-10 04:26:57.469635+05:30	4c8653af035701f9619f1ac51c63bbef37fd79150196c98d6966028b2b28a111	2026-10-10 04:26:57.469635+05:30	\N
b2ee54a4-d2e4-4c30-8bee-c7951a4e01c3	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/defaultImage;	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.470663+05:30	\N	2026-10-10 04:26:57.470663+05:30	2026-10-10 04:26:57.470663+05:30	e81f04fec8acfa955293edcc175e76f7f326d09721dce19298383cc6d9f1bda8	2026-10-10 04:26:57.470663+05:30	\N
1464103d-a2dc-4d40-86c6-7e80c31b1826	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.471676+05:30	\N	2026-10-10 04:26:57.471676+05:30	2026-10-10 04:26:57.471676+05:30	4796d263e9c415f5f5d297d32cb01212cea6a6c66099d5223538eb8606f3a6d8	2026-10-10 04:26:57.471676+05:30	\N
68808a17-98da-411d-8294-4cdd2e7c1d79	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/$%7BdefaultImage%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.472683+05:30	\N	2026-10-10 04:26:57.472683+05:30	2026-10-10 04:26:57.472683+05:30	30d3cce015bd534a6f09498113899b39c7f4e3200e6c25f229903993baf644ee	2026-10-10 04:26:57.472683+05:30	\N
bb6aeba9-d6d1-492a-bebe-4da0946fb458	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.473722+05:30	\N	2026-10-10 04:26:57.473722+05:30	2026-10-10 04:26:57.473722+05:30	f3146c52fd542cab58d12352a2cb45e279406258fe78c9a2fe52f69d981c0ce5	2026-10-10 04:26:57.473722+05:30	\N
e254ea68-46f2-4695-8f41-d646dcc92c62	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.474896+05:30	\N	2026-10-10 04:26:57.474896+05:30	2026-10-10 04:26:57.474896+05:30	f2b052a86a9b6bfbe5a390ac3eaae47abf90f7fa39b2f11e90b5dd2b2a23cd69	2026-10-10 04:26:57.474896+05:30	\N
b672183d-7129-44ce-8c5e-6cdd5326c863	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/backend/form.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.475926+05:30	\N	2026-10-10 04:26:57.475926+05:30	2026-10-10 04:26:57.475926+05:30	7f2604b25c874b5a913c6964085b7b27d6580fceea59ea3b8b095ae38e76d5c2	2026-10-10 04:26:57.475926+05:30	\N
77662bcb-190f-4d43-a916-789dd335c8e4	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/backend/form.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.476938+05:30	\N	2026-10-10 04:26:57.476938+05:30	2026-10-10 04:26:57.476938+05:30	c30d167e90bf2d8e53fd6251116d092e2bdc15f8d5b92afd0c304d1f94a241ad	2026-10-10 04:26:57.476938+05:30	\N
9b93544e-4d45-4c69-8578-e9b3a932e7b0	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_misconfiguration	Missing HttpOnly Cookie Attribute: PHPSESSID	A cookie lacks the 'HttpOnly' attribute, making it accessible to client-side JavaScript and increasing the impact of potential XSS attacks.	low	\N	\N	https://thephotopunditz.com/backend/form.php	\N	{"cookie_name": "PHPSESSID"}	Ensure the 'HttpOnly' flag is set for session and authentication cookies.	open	1.000	2026-10-10 04:26:57.477958+05:30	\N	2026-10-10 04:26:57.477958+05:30	2026-10-10 04:26:57.477958+05:30	951aff503d0a9a12548f4b7f6505239f88c6b884941baebab385b9d72cfd7632	2026-10-10 04:26:57.477958+05:30	\N
c55418d6-9e74-4ecb-9758-b28d27437938	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_misconfiguration	Missing SameSite Cookie Attribute: PHPSESSID	A cookie lacks the 'SameSite' attribute, which removes a layer of defense against Cross-Site Request Forgery (CSRF).	info	\N	\N	https://thephotopunditz.com/backend/form.php	\N	{"cookie_name": "PHPSESSID"}	Configure the 'SameSite' attribute to 'Lax' or 'Strict' depending on cross-domain requirements.	open	1.000	2026-10-10 04:26:57.479008+05:30	\N	2026-10-10 04:26:57.479008+05:30	2026-10-10 04:26:57.479008+05:30	6605ff64feacca0bda868ba384b836d45c79aecc184205312f8515f1ca7f9c6c	2026-10-10 04:26:57.479008+05:30	\N
a07aa924-ea62-4853-9b5a-d2e0d6228f02	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.480036+05:30	\N	2026-10-10 04:26:57.480036+05:30	2026-10-10 04:26:57.480036+05:30	e2d7ceef5d73b4ebf0c8d0520b335ac3e4258408ae6b89a0edd2cb77cea8f14d	2026-10-10 04:26:57.480036+05:30	\N
f636e529-0a0f-4dac-93ec-914f3d14d90c	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/thankyou.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.481126+05:30	\N	2026-10-10 04:26:57.481126+05:30	2026-10-10 04:26:57.481126+05:30	ef4ea4e776a2fdf56ca41009f86bdf8d92677067a23b098e79105b30fbeba59e	2026-10-10 04:26:57.481126+05:30	\N
6e30ef0b-b2b9-4665-8a66-5e61d8002433	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.482154+05:30	\N	2026-10-10 04:26:57.482154+05:30	2026-10-10 04:26:57.482154+05:30	2a9f6be77df5f7a653b3ced04f59b3525d0e8db863788a8f76756a29fe22870c	2026-10-10 04:26:57.482154+05:30	\N
f8e49077-1958-4d0b-8328-18b7f4d8a464	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/css/glightbox.min.css	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.48335+05:30	\N	2026-10-10 04:26:57.48335+05:30	2026-10-10 04:26:57.48335+05:30	08f7e6b5a031a90c593bbdc1777455a171a3c2e8b4f74c337834b56a21317542	2026-10-10 04:26:57.48335+05:30	\N
c427d5d3-dd1b-43bd-9be3-c55e2e85bce5	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/resolveUrl(img.src);	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.48457+05:30	\N	2026-10-10 04:26:57.48457+05:30	2026-10-10 04:26:57.48457+05:30	c98cfd8ae7e39c2e30f53c8b038068e7fea04849bca7ad76fbe7c160e1f16283	2026-10-10 04:26:57.48457+05:30	\N
1a933889-6e8f-4524-bb6f-29583251d470	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/resolveUrl(img.src);	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.485623+05:30	\N	2026-10-10 04:26:57.485623+05:30	2026-10-10 04:26:57.485623+05:30	a9f6982dc67360cb41d90b04fd8b15bcf9db2c6c6275a439bf9e2449aaec298c	2026-10-10 04:26:57.485623+05:30	\N
d73fbf06-6229-4c80-8ea9-fada7ca5523b	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.486648+05:30	\N	2026-10-10 04:26:57.486648+05:30	2026-10-10 04:26:57.486648+05:30	0ffc736cc768a43da60fa0d4b919102515da383b28118ece94ca20714a599022	2026-10-10 04:26:57.486648+05:30	\N
6f7231e0-093b-4846-9980-6f0d245f1d3b	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/photography/$%7Bfallback%7D	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.487674+05:30	\N	2026-10-10 04:26:57.487674+05:30	2026-10-10 04:26:57.487674+05:30	9aba74ea649a4e89de29541d33219ab4df160856609767025b74445e58fa2987	2026-10-10 04:26:57.487674+05:30	\N
1a92bbe7-3b9a-4c54-bd19-db914c60cc1f	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.488719+05:30	\N	2026-10-10 04:26:57.488719+05:30	2026-10-10 04:26:57.488719+05:30	ce5d66917437bd37e9d2de758fbbb34a5e71fe79410e539b84dd093f055b97e3	2026-10-10 04:26:57.488719+05:30	\N
ebd9e83c-eca4-4002-8a21-42f7419e60b1	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/assets/js/glightbox.min.js	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.489772+05:30	\N	2026-10-10 04:26:57.489772+05:30	2026-10-10 04:26:57.489772+05:30	20328e4188b480bb207370b470b5292875a864080e901fd945b52c76f3ac5da8	2026-10-10 04:26:57.489772+05:30	\N
0aadad78-abc5-4114-8109-e6d2b3841cb5	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.490935+05:30	\N	2026-10-10 04:26:57.490935+05:30	2026-10-10 04:26:57.490935+05:30	be29623e6f8cb12fb4f1511b692ec34a0175739347451524528a0b6d2cc32b37	2026-10-10 04:26:57.490935+05:30	\N
aac68567-fd8f-4e25-922d-7ca59e9e94db	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.491979+05:30	\N	2026-10-10 04:26:57.491979+05:30	2026-10-10 04:26:57.491979+05:30	ce80a49a5c895263db757fc01cdb7bae2e4eb470019c30ab338a88d8f2f69c08	2026-10-10 04:26:57.491979+05:30	\N
decdea88-4d0d-4588-8228-e9ccc6cfd80d	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.493021+05:30	\N	2026-10-10 04:26:57.493021+05:30	2026-10-10 04:26:57.493021+05:30	36ac9168cd6ce8a66f7e9c25f349522c26820fa7e83d446e52e6084a0b5b8fec	2026-10-10 04:26:57.493021+05:30	\N
4710e047-72cc-4a92-aa82-3096fe2795fe	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-teaser.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.494106+05:30	\N	2026-10-10 04:26:57.494106+05:30	2026-10-10 04:26:57.494106+05:30	a20e5229c46fc1fe2cd716a486ed69433ec570bfbce1a603c2186cb3d1de4d38	2026-10-10 04:26:57.494106+05:30	\N
6d4ba5cb-8d92-43a4-bb3a-2b1461cdfde5	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Strict-Transport-Security (HSTS) Header	The response is delivered over HTTPS but lacks the HSTS header. This leaves the application vulnerable to SSL stripping attacks during initial or subsequent connections.	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{"missing_header": "Strict-Transport-Security"}	Configure the server to include the 'Strict-Transport-Security' header with an appropriate 'max-age' directive.	open	1.000	2026-10-10 04:26:57.495174+05:30	\N	2026-10-10 04:26:57.495174+05:30	2026-10-10 04:26:57.495174+05:30	0786c6a47de2d64699bcb04c36dd89c13eda0250533ac1a1450edb7c5495a042	2026-10-10 04:26:57.495174+05:30	\N
7af3006c-daa3-4f02-b6d2-32b9571b4eb2	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://thephotopunditz.com/films/neel-and-mike-highlights.php	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:26:57.496197+05:30	\N	2026-10-10 04:26:57.496197+05:30	2026-10-10 04:26:57.496197+05:30	04c46764dc4542a144ebc3bec03614254cdd675c47451f07041ed0773e6f9ada	2026-10-10 04:26:57.496197+05:30	\N
a2df117b-6def-4832-8c6e-866c2bfae8e8	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.172501+05:30	\N	2026-10-10 04:27:25.172501+05:30	2026-10-10 04:27:25.172501+05:30	fb040869ce8ec39f609614027286a990bc11b3784213136d8d43fa2c9d452075	2026-10-10 04:27:25.172501+05:30	\N
17e7f166-5aba-4df7-8963-1d57ac594e16	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.188301+05:30	\N	2026-10-10 04:27:25.188301+05:30	2026-10-10 04:27:25.188301+05:30	05ec7f54b56e179e17fbc9fc67d11b7af4511d0eb46c2906f513b6edbe4aae44	2026-10-10 04:27:25.188301+05:30	\N
14cb1bac-079a-4e0e-a056-0a1b2ace6eb9	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.189573+05:30	\N	2026-10-10 04:27:25.189573+05:30	2026-10-10 04:27:25.189573+05:30	56bdc40f1124ce02d1206131bf44a3251c5f4218877dddfe3344e04e6eba7da7	2026-10-10 04:27:25.189573+05:30	\N
ef7f6ee4-e936-48ff-a15f-67a881c4ef6a	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.190833+05:30	\N	2026-10-10 04:27:25.190833+05:30	2026-10-10 04:27:25.190833+05:30	c4aaea5375019312723125fc9f4808d6ddd7596c78003ecad9b90e13b118e506	2026-10-10 04:27:25.190833+05:30	\N
8a573f86-aa09-46a7-9e5b-e01f707c2c92	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.192043+05:30	\N	2026-10-10 04:27:25.192043+05:30	2026-10-10 04:27:25.192043+05:30	7a6dbe8c2b43dfac81f2c353777dc8ae2438f9344a510c97c7f0e4c2ca35b296	2026-10-10 04:27:25.192043+05:30	\N
49f5c68e-a19c-4556-ac4d-4334de46c5c0	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.193161+05:30	\N	2026-10-10 04:27:25.193161+05:30	2026-10-10 04:27:25.193161+05:30	7960c9fe58faf3cbd1ff55a8ae70cdf74aef30e009c22cc36c9d769ba1f47fd4	2026-10-10 04:27:25.193161+05:30	\N
b5fa2571-eeba-4a4c-9082-3c503a62d8b9	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/video	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.194624+05:30	\N	2026-10-10 04:27:25.194624+05:30	2026-10-10 04:27:25.194624+05:30	2d8432e45622c08e2d334b88028780117a7d559ba30532f7be51defb3ebec2cb	2026-10-10 04:27:25.194624+05:30	\N
4d8f4574-b7cf-4ca8-8014-1ee7d65b8b2e	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/video	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.195726+05:30	\N	2026-10-10 04:27:25.195726+05:30	2026-10-10 04:27:25.195726+05:30	5dad2fa1083e92f722bea7a79eb7b4a100cd8012989e5d401053acade1da8c1f	2026-10-10 04:27:25.195726+05:30	\N
0a9f3ee1-7500-4b19-b54c-3754f27ea986	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/video	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.196757+05:30	\N	2026-10-10 04:27:25.196757+05:30	2026-10-10 04:27:25.196757+05:30	1bb4c04bba04de7c44a3cd0fb890b1e8e88d940f8e67db95e78354e759712f52	2026-10-10 04:27:25.196757+05:30	\N
2ebae7a5-7e53-4dfe-a647-c26da562290d	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/loya	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.229623+05:30	\N	2026-10-10 04:27:25.229623+05:30	2026-10-10 04:27:25.229623+05:30	86aa53758bd39e85cb58e70fe89eee92a42b3fb635acd2e5d773202b768ea629	2026-10-10 04:27:25.229623+05:30	\N
b7e9c803-41fc-4e7d-a58a-de06ca21f2ec	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/about	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.197783+05:30	\N	2026-10-10 04:27:25.197783+05:30	2026-10-10 04:27:25.197783+05:30	a38e27773e96d33cc1bd887dd0af774aba62c3fcf5b15da0b390e2a582fcd142	2026-10-10 04:27:25.197783+05:30	\N
6f6eb2e3-4654-4537-bb0a-536cdb71e6c0	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/about	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.199126+05:30	\N	2026-10-10 04:27:25.199126+05:30	2026-10-10 04:27:25.199126+05:30	c3ed38f12562e770cb818bb30ae13dbc2e2939bad5f3bf86a1a47e7331df26b9	2026-10-10 04:27:25.199126+05:30	\N
5cea9442-f7f5-4645-a6e1-d6c07cf3d7cc	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/about	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.20042+05:30	\N	2026-10-10 04:27:25.20042+05:30	2026-10-10 04:27:25.20042+05:30	c7997797dec8d9e2e8835777b258a99c11558de9e4b566f459d65d27018e40c0	2026-10-10 04:27:25.20042+05:30	\N
098743d5-3182-42be-8583-3bf63600dad5	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/contact	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.201905+05:30	\N	2026-10-10 04:27:25.201905+05:30	2026-10-10 04:27:25.201905+05:30	0f9f68cfac6c032f8927779a6accf16c9ad5d4009f1d185ce7a9b4452bbf9ef5	2026-10-10 04:27:25.201905+05:30	\N
36bfc96e-4525-4334-856e-29c5d860fa6f	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/contact	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.203229+05:30	\N	2026-10-10 04:27:25.203229+05:30	2026-10-10 04:27:25.203229+05:30	5a6a62a6b1e9ba2e8f293c8c4eba4a329ede51017e0d4c7b06b6122f79010da0	2026-10-10 04:27:25.203229+05:30	\N
48327c47-deb2-4ef4-b275-25737d3d76b0	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/contact	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.204355+05:30	\N	2026-10-10 04:27:25.204355+05:30	2026-10-10 04:27:25.204355+05:30	0b8b9d161ce48c2f45d712bd12cf2d069756ad7b6e9a269575621f8077674d15	2026-10-10 04:27:25.204355+05:30	\N
ed8011c9-45c1-4903-aa41-113c7e458beb	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/carrer	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.205489+05:30	\N	2026-10-10 04:27:25.205489+05:30	2026-10-10 04:27:25.205489+05:30	fbb1378235af8252e522805d7f3b25c99f29d47870f9d9b6e4aa183f29c43cbe	2026-10-10 04:27:25.205489+05:30	\N
88abd980-89b6-40ec-8ebb-d9a9d9422b18	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/carrer	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.206648+05:30	\N	2026-10-10 04:27:25.206648+05:30	2026-10-10 04:27:25.206648+05:30	0a0a72f6d9616f7b8dc85e928e48ff593e737bd2fc918975a1beb8758342efae	2026-10-10 04:27:25.206648+05:30	\N
9e02b430-e34f-4c82-82c2-04d53d22a960	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/carrer	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.207705+05:30	\N	2026-10-10 04:27:25.207705+05:30	2026-10-10 04:27:25.207705+05:30	059f0711641e8d4b40e83e672f43ea87fc441268ef8fcc707815093399f88ab9	2026-10-10 04:27:25.207705+05:30	\N
18735de2-a771-49db-9686-4397b02a6af2	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.208763+05:30	\N	2026-10-10 04:27:25.208763+05:30	2026-10-10 04:27:25.208763+05:30	be280066ce3ce46b88a8d704dd13088cd83c151ef7f010fa6c055d476a1b3fdc	2026-10-10 04:27:25.208763+05:30	\N
6b852bd1-eff2-4956-b747-42c620f0f02a	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.209923+05:30	\N	2026-10-10 04:27:25.209923+05:30	2026-10-10 04:27:25.209923+05:30	e90424557078824be6e351b0e1d11c0b243d843c3d60fe043ce8f920008c18e0	2026-10-10 04:27:25.209923+05:30	\N
e8c9c319-5361-4f0e-b8e4-7ca982bc98f6	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.211234+05:30	\N	2026-10-10 04:27:25.211234+05:30	2026-10-10 04:27:25.211234+05:30	58431f97ba37a447f2952e8b02811a327846d735fc9b81a03a15d884bbd550f8	2026-10-10 04:27:25.211234+05:30	\N
f288544f-f19e-4e55-a378-625d0338ce61	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.212323+05:30	\N	2026-10-10 04:27:25.212323+05:30	2026-10-10 04:27:25.212323+05:30	bbff7dc6c53d6fa7883863ac17e2ef5e38d7e25864652a1cd464dc9cff32b315	2026-10-10 04:27:25.212323+05:30	\N
dbb7011f-87f3-4a2d-b249-5a9624f65dc2	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/coorg	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.213352+05:30	\N	2026-10-10 04:27:25.213352+05:30	2026-10-10 04:27:25.213352+05:30	6458186097d5003a1d1ad91909b77ecbc56c6f7f062ffa9b71bcd961e9a0ee83	2026-10-10 04:27:25.213352+05:30	\N
38c0d40c-dcf4-4c40-b14f-bf5b46d0082a	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.215655+05:30	\N	2026-10-10 04:27:25.215655+05:30	2026-10-10 04:27:25.215655+05:30	275a9a3bfd308169a0368cbd8d612682c0e8281ba2d93e82036c886131c04f52	2026-10-10 04:27:25.215655+05:30	\N
ddeeab6d-a329-4dee-bfb0-73d382afe502	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.216751+05:30	\N	2026-10-10 04:27:25.216751+05:30	2026-10-10 04:27:25.216751+05:30	cda4b6462995354c4531bb5419dac4445611a39c7bfe88ece504ca80b57d27c6	2026-10-10 04:27:25.216751+05:30	\N
9145155a-9526-443c-81c5-7750d81335e7	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/taj-patna	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.217893+05:30	\N	2026-10-10 04:27:25.217893+05:30	2026-10-10 04:27:25.217893+05:30	d80b8d2ff02e9a195f6c5cdaf3f89c8607e3679d789514d0ff1d4baf3ff6b78f	2026-10-10 04:27:25.217893+05:30	\N
9d995cc9-3b17-4ea0-9131-2c6e4c9bf773	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.219044+05:30	\N	2026-10-10 04:27:25.219044+05:30	2026-10-10 04:27:25.219044+05:30	1d100fbb696e7ac8298b7486be07e94eb8660bb16bb9abfc20374222f73047c4	2026-10-10 04:27:25.219044+05:30	\N
e8c62684-beb0-464b-88e7-ae417c631c7a	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.220094+05:30	\N	2026-10-10 04:27:25.220094+05:30	2026-10-10 04:27:25.220094+05:30	a73bef3d5a0aa71a333a4f3c7f076151f7087b17262f2d026344d4589bfce890	2026-10-10 04:27:25.220094+05:30	\N
9e3dd4ee-7228-4485-a261-ae267549ef24	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/orient-express	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.221122+05:30	\N	2026-10-10 04:27:25.221122+05:30	2026-10-10 04:27:25.221122+05:30	7e640ef9f980f476a2988d1cc23fab150634a180bc4bae498bcd7aece38934b7	2026-10-10 04:27:25.221122+05:30	\N
17f12cdf-0049-4c0c-8141-99f18f8c1118	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.222155+05:30	\N	2026-10-10 04:27:25.222155+05:30	2026-10-10 04:27:25.222155+05:30	6035ea1db703b092aa98dc9fdfbeb72e91cf7f09f51891ce447040bbf07a1ef3	2026-10-10 04:27:25.222155+05:30	\N
c547a060-58a8-4504-a867-5bc22f27e7a0	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.223163+05:30	\N	2026-10-10 04:27:25.223163+05:30	2026-10-10 04:27:25.223163+05:30	ead87f9f10d6c0927ec0eb89fe9454dd8e1c119b85319cd70207490ef8ae7c8f	2026-10-10 04:27:25.223163+05:30	\N
58aa0f35-c04a-493c-a361-3f19d030e3e0	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.224213+05:30	\N	2026-10-10 04:27:25.224213+05:30	2026-10-10 04:27:25.224213+05:30	90877d891d261a4364c4ce46c5002f7d85890852bcc97ed18b326584cae89007	2026-10-10 04:27:25.224213+05:30	\N
c6e53fa1-9ca4-4ab8-bbc0-7dfd111d82c1	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.225241+05:30	\N	2026-10-10 04:27:25.225241+05:30	2026-10-10 04:27:25.225241+05:30	642d2ef06978801745977dcfb4eb66349e6091f519aa012a092cc9d0a8c10e83	2026-10-10 04:27:25.225241+05:30	\N
315bc5c7-fa2a-4be2-86ed-9a7fbe55a206	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.22644+05:30	\N	2026-10-10 04:27:25.22644+05:30	2026-10-10 04:27:25.22644+05:30	5ceac75c846892ea76f30bda154374ad1d637cee3de3266a7af9046575adc40f	2026-10-10 04:27:25.22644+05:30	\N
878d59c7-668a-4371-9b19-a965ed77d8f6	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/conrad-bengaluru	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.227479+05:30	\N	2026-10-10 04:27:25.227479+05:30	2026-10-10 04:27:25.227479+05:30	8437c76d1ba866a9d05a88e741be99421481dad4dc9aa457f650cf3f4a0bd7da	2026-10-10 04:27:25.227479+05:30	\N
842e1060-813f-4d1d-b822-7a0b20a9cacd	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/loya	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.228489+05:30	\N	2026-10-10 04:27:25.228489+05:30	2026-10-10 04:27:25.228489+05:30	fd758623fba7985df37b7caebafe690b396986809505df6c9ba2156dff976d51	2026-10-10 04:27:25.228489+05:30	\N
bee6bff3-9e8c-43b4-97cd-e2faf4e2734b	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.232018+05:30	\N	2026-10-10 04:27:25.232018+05:30	2026-10-10 04:27:25.232018+05:30	0b3527539a012f828e66b46c22c87885e462e78546bb4b2855bfbe8eb1c6fddd	2026-10-10 04:27:25.232018+05:30	\N
30d0f8c4-5d64-4c2e-a88e-49b2162ed094	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.233121+05:30	\N	2026-10-10 04:27:25.233121+05:30	2026-10-10 04:27:25.233121+05:30	29608f9e57d7b942c00ef001b896b5bec0fb80d4127189071293c5127f9053b1	2026-10-10 04:27:25.233121+05:30	\N
577a6d08-8221-48cb-b30d-fba314d7f41c	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/spicy-duck	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.234447+05:30	\N	2026-10-10 04:27:25.234447+05:30	2026-10-10 04:27:25.234447+05:30	e195c13141d0d1a94fe80ccddc2f83958dea9692a02debc385e13259d8f2c0ae	2026-10-10 04:27:25.234447+05:30	\N
f92eb8f0-e4e1-4f79-95d7-f3a637866cd2	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.235508+05:30	\N	2026-10-10 04:27:25.235508+05:30	2026-10-10 04:27:25.235508+05:30	3f1251e57448299d39c4b7ddc2f923ad3cd9acde518f809dccaaca6e69d10bcb	2026-10-10 04:27:25.235508+05:30	\N
0d5c4ec3-b54d-42b5-b3f9-7b8f093313d1	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.236544+05:30	\N	2026-10-10 04:27:25.236544+05:30	2026-10-10 04:27:25.236544+05:30	7976ac6994da8454412cd398eaa3008016ab52528af1dd252bfc1bb78bf9a231	2026-10-10 04:27:25.236544+05:30	\N
2b8c44f5-5f84-420c-bd7e-37776889265f	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.237585+05:30	\N	2026-10-10 04:27:25.237585+05:30	2026-10-10 04:27:25.237585+05:30	9d6b9f61844444c701a6e8aa1e8f98cf42292a253061af264f75bf653d86b7db	2026-10-10 04:27:25.237585+05:30	\N
80c5d80c-8f5d-4139-b204-5574860361c4	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.238613+05:30	\N	2026-10-10 04:27:25.238613+05:30	2026-10-10 04:27:25.238613+05:30	af3a11a930389620f8ba0e774805b73124da81fd9600522df4917631cf248b10	2026-10-10 04:27:25.238613+05:30	\N
fc003678-4225-49b0-8da7-7992af652b65	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.23963+05:30	\N	2026-10-10 04:27:25.23963+05:30	2026-10-10 04:27:25.23963+05:30	0d305f93c1a1f16738917352eafc61e2675959ca29b4f0b31b68f14586e5f3d4	2026-10-10 04:27:25.23963+05:30	\N
b5d73afb-366b-494a-a9e5-134ea910eeae	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/the-blue-bar	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.240638+05:30	\N	2026-10-10 04:27:25.240638+05:30	2026-10-10 04:27:25.240638+05:30	176581653a8827ff8bee0abff1582813d141d8b48d7ca864ba2944c6ce586f9f	2026-10-10 04:27:25.240638+05:30	\N
ad317b78-f48b-4efb-8324-b7998c5defaf	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.241855+05:30	\N	2026-10-10 04:27:25.241855+05:30	2026-10-10 04:27:25.241855+05:30	d35f2e7c431b16320332b8316139199ada2f123e69e45fac0f660a3381f22589	2026-10-10 04:27:25.241855+05:30	\N
9849c172-8884-4098-ba70-bdb4626ae49b	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.24304+05:30	\N	2026-10-10 04:27:25.24304+05:30	2026-10-10 04:27:25.24304+05:30	6f5191e8c33efcd0aa116b8af326d07c66c905a2b55bcb048560a487dc66d2de	2026-10-10 04:27:25.24304+05:30	\N
334e4175-4191-4c3b-9f1c-3f12165cee4b	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/gateway-bekal	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.244105+05:30	\N	2026-10-10 04:27:25.244105+05:30	2026-10-10 04:27:25.244105+05:30	659240780036812e338bea8df76ea9d4ef222416f1baa2581fda1a3667d07b09	2026-10-10 04:27:25.244105+05:30	\N
2c04ea15-35e9-4183-a83f-195f61961289	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.245125+05:30	\N	2026-10-10 04:27:25.245125+05:30	2026-10-10 04:27:25.245125+05:30	270e96b58395c537f7c1dfc87938fef075fb5b70330fedc1cc37da03971474db	2026-10-10 04:27:25.245125+05:30	\N
e4482828-549a-4020-a2fd-b49e41962141	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.246555+05:30	\N	2026-10-10 04:27:25.246555+05:30	2026-10-10 04:27:25.246555+05:30	3716b6d0e7013a6582e36e46261e2bf5390387d5f8d90d683f8591f9f9902361	2026-10-10 04:27:25.246555+05:30	\N
519a3703-aa59-48ae-9a7a-546dad7d3a38	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/zhen-zhu	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.247629+05:30	\N	2026-10-10 04:27:25.247629+05:30	2026-10-10 04:27:25.247629+05:30	b111495c24127dc5fbf56f0566e3cc131e7f2beb658ebd45bc0a10c18f2822c3	2026-10-10 04:27:25.247629+05:30	\N
b149b371-4dad-46c0-bc2b-54b232c4c5e0	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.248675+05:30	\N	2026-10-10 04:27:25.248675+05:30	2026-10-10 04:27:25.248675+05:30	3d9d019cecd3c6bda27dd66eebc3723e898e0e17788ef18e319df3fecea7c8b3	2026-10-10 04:27:25.248675+05:30	\N
e00b0b29-4170-4cd3-9457-1516e25bf64d	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.249801+05:30	\N	2026-10-10 04:27:25.249801+05:30	2026-10-10 04:27:25.249801+05:30	948e861dacb52b3196ba040857a184322baab2e62c4311e8f322ee431f4b6b58	2026-10-10 04:27:25.249801+05:30	\N
d0f8a845-712b-40f3-8de4-c47c9bd80418	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/capital-kitchen	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.251006+05:30	\N	2026-10-10 04:27:25.251006+05:30	2026-10-10 04:27:25.251006+05:30	bb1725bf14db13127c24b39fef2ac2fe89b038acdb7a93e0007858b3b522cd55	2026-10-10 04:27:25.251006+05:30	\N
5cda51eb-7d9e-4735-9d17-eef3a6623263	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.252172+05:30	\N	2026-10-10 04:27:25.252172+05:30	2026-10-10 04:27:25.252172+05:30	57f65c91568e12f5e5afdb0139ea1a278e41613f084817ccfb0da147e4cba214	2026-10-10 04:27:25.252172+05:30	\N
6abab44a-0b20-4452-98bf-594b40b16bcb	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.253341+05:30	\N	2026-10-10 04:27:25.253341+05:30	2026-10-10 04:27:25.253341+05:30	517a802d5a504eeecefaa25373eae8a7a458125159eeaf0e073ed99cc9a0217a	2026-10-10 04:27:25.253341+05:30	\N
5277ec0c-3cfe-4443-b76d-cf5d018e4fb0	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/the-tea-lounge	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.254514+05:30	\N	2026-10-10 04:27:25.254514+05:30	2026-10-10 04:27:25.254514+05:30	b9de0b26441b049335d12aca1fc6bdbfe2f1c53c0eda61a76f359ffdd092eaad	2026-10-10 04:27:25.254514+05:30	\N
94d06b0f-3543-4af5-a3ac-e9e0315fc773	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.255631+05:30	\N	2026-10-10 04:27:25.255631+05:30	2026-10-10 04:27:25.255631+05:30	941fafe01f230bedc72fceb29423847240a90e23c6c789b1cf2762d726cab5bc	2026-10-10 04:27:25.255631+05:30	\N
69f671e0-4acf-4cc7-a96b-f8abecbc164e	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.256666+05:30	\N	2026-10-10 04:27:25.256666+05:30	2026-10-10 04:27:25.256666+05:30	80b5be38faa1aa0c7c196b8c9f0feb22e63fbc91820c9f522bea972745d7ac7e	2026-10-10 04:27:25.256666+05:30	\N
2a819d61-3166-4039-aeb4-158dfa2ef8a2	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.257821+05:30	\N	2026-10-10 04:27:25.257821+05:30	2026-10-10 04:27:25.257821+05:30	28ddde0b0a4f3a49ab6c102d77f1a4c15b3bd627bb562e6b79bbcbc9817173db	2026-10-10 04:27:25.257821+05:30	\N
666d0ae5-bd32-46e7-897a-77bacaa5e1ef	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/404	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.259018+05:30	\N	2026-10-10 04:27:25.259018+05:30	2026-10-10 04:27:25.259018+05:30	642645110f6f35b817b24823c3fd60fa05f0246e161f8a170634276fa3b70735	2026-10-10 04:27:25.259018+05:30	\N
aeacd284-b7ee-4a62-968a-3c010fac4ef9	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/404	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.260046+05:30	\N	2026-10-10 04:27:25.260046+05:30	2026-10-10 04:27:25.260046+05:30	87e0a351ee0d69d67cabec2083c2c9878e18dbe062cc14ad7d4e663d6f4feb0e	2026-10-10 04:27:25.260046+05:30	\N
50209c67-6054-4f98-9d2f-7e816ffb37b7	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/404	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.26109+05:30	\N	2026-10-10 04:27:25.26109+05:30	2026-10-10 04:27:25.26109+05:30	13a7f019c2ab620022e9144eb95293b09a76d2d4e3f5a2bb8cd4f0896710ce64	2026-10-10 04:27:25.26109+05:30	\N
75813e53-c91a-4a5b-b799-ffa94e11f5cb	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/carrer	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.277313+05:30	\N	2026-10-10 04:27:25.277313+05:30	2026-10-10 04:27:25.277313+05:30	f41b4274ec22a9aef3e5fe004394be65d93f7e8967061587b7512c0a8aab648a	2026-10-10 04:27:25.277313+05:30	\N
f69adbf2-bff0-4e11-bc5d-709bf53e12a9	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/projects	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.262152+05:30	\N	2026-10-10 04:27:25.262152+05:30	2026-10-10 04:27:25.262152+05:30	32b18fe3c7814a48acf2000e82de996ddeac5b01e53dbc62ec6445be192c3768	2026-10-10 04:27:25.262152+05:30	\N
183f9aa0-99fc-427d-9030-c40c92b65e5f	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/projects	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.263205+05:30	\N	2026-10-10 04:27:25.263205+05:30	2026-10-10 04:27:25.263205+05:30	d22bf406ba847cbd1d008c0191d093d11f7b17aa0d2501838c74535e02e0ed28	2026-10-10 04:27:25.263205+05:30	\N
e1a2aa52-52f0-4db1-a20c-f59ec0bc7159	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/projects	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.264246+05:30	\N	2026-10-10 04:27:25.264246+05:30	2026-10-10 04:27:25.264246+05:30	2f0546f9c39540899a1fb25d2d910b905e9392dfcced719df240765148cdba7b	2026-10-10 04:27:25.264246+05:30	\N
79da19f3-57ef-43aa-af62-0a7a395d621c	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/video	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.265249+05:30	\N	2026-10-10 04:27:25.265249+05:30	2026-10-10 04:27:25.265249+05:30	46eb7c145b6f96b4c7c3fce9be85e29d9996a07e535305f4b2ad363e7dd2f5b0	2026-10-10 04:27:25.265249+05:30	\N
b01ab36f-cae8-4090-b8a1-7bc00756b866	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/video	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.266458+05:30	\N	2026-10-10 04:27:25.266458+05:30	2026-10-10 04:27:25.266458+05:30	dcae67eef6e352c4bde9a8d1a26d7d6b730d01132ef7041e5dd62e33876012e3	2026-10-10 04:27:25.266458+05:30	\N
f14eba03-1c94-4acb-96d1-dc803da93c87	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/video	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.267482+05:30	\N	2026-10-10 04:27:25.267482+05:30	2026-10-10 04:27:25.267482+05:30	e3f1aca2c2e240761f0a6ff1daa1e67eebf42ea9744c8d9f0200cf39d5b980ce	2026-10-10 04:27:25.267482+05:30	\N
d6b2b4ea-2bb9-4d06-9207-fdad4146301a	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/about	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.268518+05:30	\N	2026-10-10 04:27:25.268518+05:30	2026-10-10 04:27:25.268518+05:30	49ea9b6685d4ebeda2bfc39c0915cbb32dc9358eef204f46d6f7014277f29bed	2026-10-10 04:27:25.268518+05:30	\N
1ca8f4b6-236c-44f8-9288-e80a73b00987	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/about	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.269544+05:30	\N	2026-10-10 04:27:25.269544+05:30	2026-10-10 04:27:25.269544+05:30	de0b7b3d4f51770551b7aff39918ce2ef20728fbaa825056b3c328d85243d697	2026-10-10 04:27:25.269544+05:30	\N
feb72bbf-6795-4198-aa44-a1920643f4e9	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/about	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.27055+05:30	\N	2026-10-10 04:27:25.27055+05:30	2026-10-10 04:27:25.27055+05:30	b4c7f1ee48d3383bb396455d670a74e9bcd0218826673d3844e684a357055060	2026-10-10 04:27:25.27055+05:30	\N
909fadd2-790d-4c53-a607-7e3462911f2b	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/contact	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.271689+05:30	\N	2026-10-10 04:27:25.271689+05:30	2026-10-10 04:27:25.271689+05:30	38945443e7186cb70596fd02557b0495e787dcbf73ff2fc7ae364d4b2a651589	2026-10-10 04:27:25.271689+05:30	\N
2c0e5a64-7033-4acc-bbe9-4a2f4f23d88d	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/contact	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.272767+05:30	\N	2026-10-10 04:27:25.272767+05:30	2026-10-10 04:27:25.272767+05:30	7f634e330ec0d64dd0242a5bbe43185745e4c53b04268b80e487696e42420255	2026-10-10 04:27:25.272767+05:30	\N
fabf729c-0541-4e6f-9f40-b5112a0a629c	e684818b-89b5-4930-9639-d09d51978b3d	information_disclosure	Server Version Disclosure	The Server response header discloses a specific software version, which can aid attackers in identifying known CVEs.	info	\N	\N	https://terminalonestudio.com/projects/contact	\N	{"server_header": "Framer/26fa766"}	Configure the web server to omit version numbers or mask the Server header.	open	0.850	2026-10-10 04:27:25.273956+05:30	\N	2026-10-10 04:27:25.273956+05:30	2026-10-10 04:27:25.273956+05:30	c2a5a745081769a53739795725f04a924257623ee3b76256bbbf46e33551a145	2026-10-10 04:27:25.273956+05:30	\N
c42dd346-c1e6-478b-8542-77012f6c51ec	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Content-Security-Policy (CSP) Header	The response lacks a CSP header. While not a vulnerability itself, missing CSP removes a critical defense-in-depth layer against Cross-Site Scripting (XSS).	low	\N	\N	https://terminalonestudio.com/projects/carrer	\N	{"missing_header": "Content-Security-Policy"}	Implement a strict Content-Security-Policy to restrict the sources of executable scripts and other resources.	open	1.000	2026-10-10 04:27:25.275111+05:30	\N	2026-10-10 04:27:25.275111+05:30	2026-10-10 04:27:25.275111+05:30	fcce08b0f185e3d63f443e7f327b7089c55796e6b419bb3cd08b6d4a9d063809	2026-10-10 04:27:25.275111+05:30	\N
ae33e930-f3e0-4f78-8f06-4f89fc7e5494	e684818b-89b5-4930-9639-d09d51978b3d	security_headers	Missing Referrer-Policy Header	The response does not explicitly set a Referrer-Policy, which may lead to sensitive URLs being leaked in the Referer header to external sites.	info	\N	\N	https://terminalonestudio.com/projects/carrer	\N	{"missing_header": "Referrer-Policy"}	Set an appropriate Referrer-Policy such as 'strict-origin-when-cross-origin'.	open	1.000	2026-10-10 04:27:25.276146+05:30	\N	2026-10-10 04:27:25.276146+05:30	2026-10-10 04:27:25.276146+05:30	565429bdc6bc652ce30defb38977993da52f55a27a5cb63598421971e0a00ef1	2026-10-10 04:27:25.276146+05:30	\N
\.


--
-- TOC entry 5329 (class 0 OID 33982)
-- Dependencies: 229
-- Data for Name: reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.reports (id, scan_id, scan_summary, security_findings, ai_analysis, intrusion_analysis, recommendations, created_at) FROM stdin;
\.


--
-- TOC entry 5327 (class 0 OID 33961)
-- Dependencies: 227
-- Data for Name: risk_scores; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.risk_scores (id, scan_id, severity_score, ai_confidence, impact_score, final_score, priority, created_at) FROM stdin;
\.


--
-- TOC entry 5338 (class 0 OID 34943)
-- Dependencies: 239
-- Data for Name: scan_endpoints; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_endpoints (id, scan_id, url, http_method, endpoint_type, depth, status_code, content_type, discovered_from, crawl_status, error_message, discovered_at, crawled_at) FROM stdin;
424	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/aayush---sneha.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.063767+05:30	\N
425	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/aayushi---raahat.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.065458+05:30	\N
426	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/bride.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.065953+05:30	\N
427	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/chadani---chirag.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.066386+05:30	\N
428	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/j---p.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.066787+05:30	\N
429	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/megha---ankit.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.067199+05:30	\N
430	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/neel---mike.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.067585+05:30	\N
431	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/nikaah.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.067941+05:30	\N
432	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/ninad---rupali.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.06829+05:30	\N
433	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/prerita---bhairav.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.068632+05:30	\N
434	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/r---o.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.068978+05:30	\N
435	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/s---a.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.069321+05:30	\N
436	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/wedding-highlights.php	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.069673+05:30	\N
437	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7Bfallback%7D	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.070049+05:30	\N
438	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7BlinkUrl%7D	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.070394+05:30	\N
439	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7BfallbackImg%7D	GET	page	2	\N	\N	https://thephotopunditz.com/photography.php	discovered	\N	2026-10-10 04:26:39.070735+05:30	\N
475	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/conrad-bengaluru	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.114138+05:30	\N
476	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/loya	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.115933+05:30	\N
477	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/spicy-duck	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.116433+05:30	\N
478	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/raajsa-kumbhalgarh---ihcl-seleqtions	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.116819+05:30	\N
479	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/the-blue-bar	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.117203+05:30	\N
480	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/gateway-bekal	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.117592+05:30	\N
481	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/zhen-zhu	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.117963+05:30	\N
482	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/capital-kitchen	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.118306+05:30	\N
483	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/the-tea-lounge	GET	page	2	\N	\N	https://terminalonestudio.com/projects	discovered	\N	2026-10-10 04:27:16.118641+05:30	\N
440	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.422785+05:30	\N
441	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/darshan-and-chanchal-teaser.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.424462+05:30	\N
442	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/neeel-and-mike-highlights.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.424967+05:30	\N
443	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/neeel-and-mike-teaser.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.425436+05:30	\N
444	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/ninad-and-rupali-pre-wedding.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.42587+05:30	\N
445	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.426294+05:30	\N
446	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.426721+05:30	\N
447	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7BthumbnailFallback%7D	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.427174+05:30	\N
448	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.427585+05:30	\N
449	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.427981+05:30	\N
450	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.428396+05:30	\N
451	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7Bsrc%7D	GET	page	2	\N	\N	https://thephotopunditz.com/films.php	discovered	\N	2026-10-10 04:26:39.428796+05:30	\N
484	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	GET	page	2	\N	\N	https://terminalonestudio.com/projects/taj--pan-india	discovered	\N	2026-10-10 04:27:17.825839+05:30	\N
452	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/defaultImage;	GET	page	2	\N	\N	https://thephotopunditz.com/faq.php	discovered	\N	2026-10-10 04:26:39.783036+05:30	\N
485	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/404	GET	page	2	\N	\N	https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:19.18515+05:30	\N
453	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7BdefaultImage%7D	GET	page	2	\N	\N	https://thephotopunditz.com/about.php	discovered	\N	2026-10-10 04:26:40.138309+05:30	\N
486	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.703551+05:30	\N
487	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/projects	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.705308+05:30	\N
488	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/video	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.70581+05:30	\N
489	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/about	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.706259+05:30	\N
490	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/contact	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.706674+05:30	\N
491	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/carrer	GET	page	3	\N	\N	https://terminalonestudio.com/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	discovered	\N	2026-10-10 04:27:22.707059+05:30	\N
454	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/img/bg/contact-2400.webp	GET	page	2	\N	\N	https://thephotopunditz.com/contact.php	discovered	\N	2026-10-10 04:26:40.594191+05:30	\N
455	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/backend/form.php	GET	page	2	\N	\N	https://thephotopunditz.com/contact.php	discovered	\N	2026-10-10 04:26:40.595575+05:30	\N
456	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/thankyou.php	GET	page	2	\N	\N	https://thephotopunditz.com/contact.php	discovered	\N	2026-10-10 04:26:40.596059+05:30	\N
457	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/css/glightbox.min.css	GET	page	3	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	discovered	\N	2026-10-10 04:26:42.685777+05:30	\N
458	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/resolveUrl(img.src);	GET	page	3	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	discovered	\N	2026-10-10 04:26:42.687054+05:30	\N
459	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography/$%7Bfallback%7D	GET	page	3	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	discovered	\N	2026-10-10 04:26:42.68747+05:30	\N
460	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/js/glightbox.min.js	GET	page	3	\N	\N	https://thephotopunditz.com/photography/aayush---sneha.php	discovered	\N	2026-10-10 04:26:42.687924+05:30	\N
461	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/$%7Burl%7D?autoplay=1&muted=1	GET	page	3	\N	\N	https://thephotopunditz.com/films/aayush-and-sneha-teaser.php	discovered	\N	2026-10-10 04:26:48.764872+05:30	\N
462	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/neel-and-mike-teaser.php	GET	page	3	\N	\N	https://thephotopunditz.com/films/ninad-and-rupali-wedding.php	discovered	\N	2026-10-10 04:26:50.845973+05:30	\N
463	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films/neel-and-mike-highlights.php	GET	page	3	\N	\N	https://thephotopunditz.com/films/yashi-and-jinesh-pre-wedding.php	discovered	\N	2026-10-10 04:26:51.212992+05:30	\N
464	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/	GET	page	0	\N	\N	\N	discovered	\N	2026-10-10 04:27:15.73758+05:30	\N
465	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.795802+05:30	\N
466	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/video	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.796545+05:30	\N
467	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/about	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.797033+05:30	\N
468	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/contact	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.797464+05:30	\N
469	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/carrer	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.797864+05:30	\N
470	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/taj--pan-india	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.798387+05:30	\N
471	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/coorg	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.798751+05:30	\N
472	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/taj-patna	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.799095+05:30	\N
473	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/projects/orient-express	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.79944+05:30	\N
474	e684818b-89b5-4930-9639-d09d51978b3d	https://terminalonestudio.com/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	GET	page	1	\N	\N	https://terminalonestudio.com/	discovered	\N	2026-10-10 04:27:15.799879+05:30	\N
403	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/	GET	page	0	\N	\N	\N	discovered	\N	2026-10-10 04:26:35.106301+05:30	\N
404	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/favicon.ico	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.178134+05:30	\N
405	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/favicon.png	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.178681+05:30	\N
406	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/css/output.css	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.179139+05:30	\N
407	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/css/aos.css	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.179565+05:30	\N
408	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/css/swiper-bundle.min.css	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.179969+05:30	\N
409	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/fonts/BodoniModa.ttf	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.181689+05:30	\N
410	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/fonts/CaviarDreams.ttf	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.18217+05:30	\N
411	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/fonts/IbarraRealNova.ttf	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.183163+05:30	\N
412	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/fonts/OpenSans.ttf	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.184184+05:30	\N
413	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/fonts/PoiretOne-Regular.ttf	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.185316+05:30	\N
414	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/photography.php	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.186616+05:30	\N
415	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/films.php	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.187573+05:30	\N
416	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/faq.php	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.188422+05:30	\N
417	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/about.php	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.18902+05:30	\N
418	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/contact.php	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.189516+05:30	\N
419	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/js/swiper-bundle.min.js	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.190085+05:30	\N
420	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/assets/js/aos.js	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.190545+05:30	\N
421	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/fallback;	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.19108+05:30	\N
422	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/featsBg.find(img	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.19163+05:30	\N
423	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	https://thephotopunditz.com/$%7Btest.img%7D	GET	page	1	\N	\N	https://thephotopunditz.com/	discovered	\N	2026-10-10 04:26:35.192069+05:30	\N
\.


--
-- TOC entry 5331 (class 0 OID 34002)
-- Dependencies: 231
-- Data for Name: scan_results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scan_results (id, scan_id, result_type, title, description, raw_data, created_at) FROM stdin;
1	1	string	string	string	string	2026-08-25 16:50:01.470444
2	1	string	string	string	string	2026-08-25 16:55:55.549205
\.


--
-- TOC entry 5333 (class 0 OID 34502)
-- Dependencies: 233
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scans (id, user_id, target_url, scan_type, status, started_at, completed_at, error_message, findings_count, critical_count, high_count, scan_config, created_at, updated_at, spider, passive, active, scope_type, authorization_confirmed, crawl_depth, max_pages, request_delay_ms, javascript_crawling, follow_redirects, security_checks, excluded_paths, authentication_type, pages_discovered, requests_analyzed, endpoints_found) FROM stdin;
a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://thephotopunditz.com/	standard	completed	2026-10-10 04:26:35.117018+05:30	2026-10-10 04:26:57.496814+05:30	\N	126	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 100, "scan_type": "standard", "scope_type": "domain", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 250, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 20}	2026-10-10 04:26:35.098725+05:30	2026-10-10 04:26:57.496814+05:30	t	t	f	domain	f	5	100	250	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	61	61	61
e684818b-89b5-4930-9639-d09d51978b3d	010752b0-dc79-4ad4-8293-6f4f7da62c57	https://terminalonestudio.com/	standard	completed	2026-10-10 04:27:15.740405+05:30	2026-10-10 04:27:25.277968+05:30	\N	81	0	0	{"active": false, "spider": true, "passive": true, "max_pages": 100, "scan_type": "standard", "scope_type": "domain", "user_agent": "", "crawl_depth": 5, "custom_headers": {}, "excluded_paths": [], "security_checks": ["sql_injection", "xss", "csrf", "security_headers"], "follow_redirects": true, "request_delay_ms": 250, "authentication_type": "none", "javascript_crawling": false, "authorization_confirmed": false, "max_concurrent_requests": 1, "request_timeout_seconds": 20}	2026-10-10 04:27:15.729859+05:30	2026-10-10 04:27:25.277968+05:30	t	t	f	domain	f	5	100	250	f	t	["sql_injection", "xss", "csrf", "security_headers"]	[]	none	28	28	28
\.


--
-- TOC entry 5321 (class 0 OID 33887)
-- Dependencies: 221
-- Data for Name: traffic_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.traffic_logs (id, source_ip, method, endpoint, status_code, user_agent, classification, confidence, created_at, scan_id, event_type, severity, evidence) FROM stdin;
403	127.0.0.1	GET	/assets/fonts/OpenSans.ttf	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:38.357757	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-font-ttf"}}
419	127.0.0.1	GET	/photography/j---p.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:44.173375	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/j---p.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
435	127.0.0.1	GET	/films/ninad-and-rupali-pre-wedding.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:50.466437	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
451	127.0.0.1	GET	/assets/js/glightbox.min.js	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:56.162274	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-javascript"}}
467	127.0.0.1	GET	/projects/loya	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:19.974868	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
404	127.0.0.1	GET	/assets/fonts/PoiretOne-Regular.ttf	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:38.696639	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-font-ttf"}}
420	127.0.0.1	GET	/photography/megha---ankit.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:44.562681	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/megha---ankit.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
436	127.0.0.1	GET	/films/ninad-and-rupali-wedding.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:50.840846	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
452	127.0.0.1	GET	/films/$%7Burl%7D?autoplay=1&muted=1	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:56.526332	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
468	127.0.0.1	GET	/projects/spicy-duck	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:20.28483	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
405	127.0.0.1	GET	/photography.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:39.0573	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
421	127.0.0.1	GET	/photography/neel---mike.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:44.939811	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/neel---mike.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
437	127.0.0.1	GET	/films/yashi-and-jinesh-pre-wedding.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:51.206672	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
453	127.0.0.1	GET	/films/neel-and-mike-teaser.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:56.908667	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
469	127.0.0.1	GET	/projects/raajsa-kumbhalgarh---ihcl-seleqtions	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:27:20.632083	e684818b-89b5-4930-9639-d09d51978b3d	http_request	high	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/projects/raajsa-kumbhalgarh---ihcl-seleqtions", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
406	127.0.0.1	GET	/films.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:39.417037	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
422	127.0.0.1	GET	/photography/nikaah.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:45.319206	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
438	127.0.0.1	GET	/$%7BthumbnailFallback%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:51.565972	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
454	127.0.0.1	GET	/films/neel-and-mike-highlights.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:57.280625	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
470	127.0.0.1	GET	/projects/the-blue-bar	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:20.977804	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
407	127.0.0.1	GET	/faq.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:39.777467	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
423	127.0.0.1	GET	/photography/ninad---rupali.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:45.814908	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/ninad---rupali.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
439	127.0.0.1	GET	/%60$%7Bbase%7D/assets/img/film/Films3.mp4%60;	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:51.920246	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
455	127.0.0.1	GET	/	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:15.781222	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
471	127.0.0.1	GET	/projects/gateway-bekal	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:21.324586	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
408	127.0.0.1	GET	/about.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:40.132718	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
424	127.0.0.1	GET	/photography/prerita---bhairav.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:46.183363	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/prerita---bhairav.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
440	127.0.0.1	GET	/%60$%7Bbase%7D/assets/img/film/Films1.mp4%60;	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:52.277867	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
456	127.0.0.1	GET	/projects	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:16.105143	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
472	127.0.0.1	GET	/projects/zhen-zhu	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:21.666175	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
409	127.0.0.1	GET	/contact.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:40.588388	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
425	127.0.0.1	GET	/photography/r---o.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:46.571957	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/r---o.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
441	127.0.0.1	GET	/%60$%7Bbase%7D/assets/img/film/Films2.mp4%60;	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:52.642838	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
457	127.0.0.1	GET	/video	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:16.443442	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
473	127.0.0.1	GET	/projects/capital-kitchen	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:22.009655	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
410	127.0.0.1	GET	/assets/js/swiper-bundle.min.js	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:40.924353	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-javascript"}}
426	127.0.0.1	GET	/photography/s---a.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:46.9562	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/s---a.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
442	127.0.0.1	GET	/$%7Bsrc%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:52.997883	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
458	127.0.0.1	GET	/about	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:16.789646	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
474	127.0.0.1	GET	/projects/the-tea-lounge	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:22.353744	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
411	127.0.0.1	GET	/assets/js/aos.js	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:41.253384	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-javascript"}}
427	127.0.0.1	GET	/photography/wedding-highlights.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:47.324159	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
443	127.0.0.1	GET	/defaultImage;	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:53.353714	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
459	127.0.0.1	GET	/contact	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:17.132343	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
475	127.0.0.1	GET	/projects/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:22.695912	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
412	127.0.0.1	GET	/fallback;	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:41.611621	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
428	127.0.0.1	GET	/$%7Bfallback%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:47.670265	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
444	127.0.0.1	GET	/$%7BdefaultImage%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:53.716878	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
460	127.0.0.1	GET	/carrer	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:17.464795	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
476	127.0.0.1	GET	/404	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:23.040026	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
413	127.0.0.1	GET	/featsBg.find(img	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:41.968369	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
429	127.0.0.1	GET	/$%7BlinkUrl%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:48.023523	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
445	127.0.0.1	GET	/assets/img/bg/contact-2400.webp	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:54.055666	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "image/webp"}}
461	127.0.0.1	GET	/projects/taj--pan-india	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:27:17.809349	e684818b-89b5-4930-9639-d09d51978b3d	http_request	high	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/projects/taj--pan-india", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
477	127.0.0.1	GET	/projects	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:23.385422	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
414	127.0.0.1	GET	/$%7Btest.img%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:42.312285	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
430	127.0.0.1	GET	/$%7BfallbackImg%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:48.38696	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
446	127.0.0.1	GET	/backend/form.php	403	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:54.417275	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/json"}}
462	127.0.0.1	GET	/projects/coorg	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:18.151507	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
478	127.0.0.1	GET	/projects/projects	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:23.72583	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
415	127.0.0.1	GET	/photography/aayush---sneha.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:42.674045	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/aayush---sneha.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
431	127.0.0.1	GET	/films/aayush-and-sneha-teaser.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:48.758998	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
447	127.0.0.1	GET	/thankyou.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:54.772539	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
463	127.0.0.1	GET	/projects/taj-patna	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:18.494061	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
479	127.0.0.1	GET	/projects/video	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:24.068735	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
416	127.0.0.1	GET	/photography/aayushi---raahat.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:43.049462	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/aayushi---raahat.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
432	127.0.0.1	GET	/films/darshan-and-chanchal-teaser.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:49.135256	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
448	127.0.0.1	GET	/assets/css/glightbox.min.css	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:55.117458	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/css"}}
464	127.0.0.1	GET	/projects/orient-express	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:18.83575	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
480	127.0.0.1	GET	/projects/about	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:24.411092	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
417	127.0.0.1	GET	/photography/bride.php	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:43.42701	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
433	127.0.0.1	GET	/films/neeel-and-mike-highlights.php	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:49.734332	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
449	127.0.0.1	GET	/photography/resolveUrl(img.src);	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:55.461227	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
465	127.0.0.1	GET	/t,r.target=i,r.rel=e,document.body.appendChild(r),r.click(),r.remove()%7Dfunction	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:19.178067	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
481	127.0.0.1	GET	/projects/contact	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:24.75208	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
395	127.0.0.1	GET	/favicon.ico	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:35.498938	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "image/x-icon"}}
418	127.0.0.1	GET	/photography/chadani---chirag.php	200	AI-WebSecTest-PassiveScanner/1.0	SQL Injection	0.7	2026-10-10 04:26:43.798962	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	high	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}, "detection_matches": [{"reason": "SQL comment delimiter detected", "ruleId": "RULE-SQLI-001", "evidence": {"matchedContext": "/photography/chadani---chirag.php", "matchedPattern": "/(?:--|#|\\\\/\\\\*).*$/i"}, "severity": "high", "confidence": 0.7, "classification": "SQL Injection"}]}
396	127.0.0.1	GET	/favicon.png	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:35.828598	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "image/png"}}
434	127.0.0.1	GET	/films/neeel-and-mike-teaser.php	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:50.088187	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
397	127.0.0.1	GET	/assets/css/output.css	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:36.170177	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/css"}}
450	127.0.0.1	GET	/photography/$%7Bfallback%7D	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:55.821503	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
398	127.0.0.1	GET	/assets/css/aos.css	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:36.512921	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/css"}}
466	127.0.0.1	GET	/projects/conrad-bengaluru	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:19.521779	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
399	127.0.0.1	GET	/assets/css/swiper-bundle.min.css	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:36.856091	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/css"}}
482	127.0.0.1	GET	/projects/carrer	404	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:27:25.093763	e684818b-89b5-4930-9639-d09d51978b3d	http_request	info	{"headers": {"server": "Framer/26fa766", "content-type": "text/html"}}
400	127.0.0.1	GET	/assets/fonts/BodoniModa.ttf	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:37.291306	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-font-ttf"}}
401	127.0.0.1	GET	/assets/fonts/CaviarDreams.ttf	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:37.633965	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-font-ttf"}}
402	127.0.0.1	GET	/assets/fonts/IbarraRealNova.ttf	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:37.97839	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "application/x-font-ttf"}}
394	127.0.0.1	GET	/	200	AI-WebSecTest-PassiveScanner/1.0	benign	0.95	2026-10-10 04:26:35.165334	a0aeedbc-fc63-48ee-a383-a4f34c7ecb78	http_request	info	{"headers": {"server": "hcdn", "content-type": "text/html; charset=UTF-8"}}
\.


--
-- TOC entry 5332 (class 0 OID 34481)
-- Dependencies: 232
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, full_name, role, is_active, last_login_at, created_at, updated_at) FROM stdin;
f747336e-23e4-45fc-8236-0c405c66d66a	analyst@example.test	$2b$12$EfwMs.au00Ftz93W7VpylelmWwuE.MrQN5T637hp5zVZ8jmczoKVi	Demo Security Analyst	analyst	t	2026-10-03 19:44:07.682591+05:30	2026-10-03 19:42:34.24247+05:30	2026-10-03 19:56:46.80992+05:30
525c3ae7-38c3-437b-b1c4-4aca10151a2a	sayali@gmail.com	$2b$12$XKRKUkm89Z2s8ADbKOLN/.SRVOSxg7mj455.qsoROqSUQZSS1b8Um	\N	analyst	t	\N	2026-10-09 21:11:09.277303+05:30	2026-10-09 21:11:09.277303+05:30
010752b0-dc79-4ad4-8293-6f4f7da62c57	sayali123@gmail.com	$2b$12$rlJMCOczWVmXbpFeMQx5suEav7NxyBdD8PesU4rJot7/0R81LLJBm	Sayali Shelavale	analyst	t	2026-10-10 05:05:23.408565+05:30	2026-10-03 19:44:34.440962+05:30	2026-10-10 05:05:23.408565+05:30
\.


--
-- TOC entry 5323 (class 0 OID 33920)
-- Dependencies: 223
-- Data for Name: vulnerabilities; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vulnerabilities (id, scan_id, type, severity, confidence, description, recommendation, status, created_at) FROM stdin;
1	1	string	string	0	string	string	open	2026-08-25 16:54:55.908134
2	1	string	string	0	string	string	open	2026-08-25 16:56:23.641013
\.


--
-- TOC entry 5361 (class 0 OID 0)
-- Dependencies: 235
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 538, true);


--
-- TOC entry 5362 (class 0 OID 0)
-- Dependencies: 224
-- Name: ai_predictions_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.ai_predictions_id_seq', 1, false);


--
-- TOC entry 5363 (class 0 OID 0)
-- Dependencies: 228
-- Name: reports_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.reports_id_seq', 1, false);


--
-- TOC entry 5364 (class 0 OID 0)
-- Dependencies: 226
-- Name: risk_scores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.risk_scores_id_seq', 1, false);


--
-- TOC entry 5365 (class 0 OID 0)
-- Dependencies: 238
-- Name: scan_endpoints_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_endpoints_id_seq', 491, true);


--
-- TOC entry 5366 (class 0 OID 0)
-- Dependencies: 230
-- Name: scan_results_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scan_results_id_seq', 2, true);


--
-- TOC entry 5367 (class 0 OID 0)
-- Dependencies: 220
-- Name: traffic_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.traffic_logs_id_seq', 482, true);


--
-- TOC entry 5368 (class 0 OID 0)
-- Dependencies: 222
-- Name: vulnerabilities_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vulnerabilities_id_seq', 2, true);


--
-- TOC entry 5119 (class 2606 OID 34593)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5090 (class 2606 OID 33953)
-- Name: ai_predictions ai_predictions_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.ai_predictions
    ADD CONSTRAINT ai_predictions_pkey PRIMARY KEY (id);


--
-- TOC entry 5142 (class 2606 OID 35156)
-- Name: alert_audit_logs alert_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5139 (class 2606 OID 35130)
-- Name: alert_notes alert_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 5131 (class 2606 OID 35092)
-- Name: alerts alerts_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_pkey PRIMARY KEY (id);


--
-- TOC entry 5148 (class 2606 OID 35216)
-- Name: finding_audit_logs finding_audit_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_audit_logs
    ADD CONSTRAINT finding_audit_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5145 (class 2606 OID 35190)
-- Name: finding_notes finding_notes_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_notes
    ADD CONSTRAINT finding_notes_pkey PRIMARY KEY (id);


--
-- TOC entry 5113 (class 2606 OID 34567)
-- Name: findings findings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_pkey PRIMARY KEY (id);


--
-- TOC entry 5097 (class 2606 OID 33992)
-- Name: reports reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_pkey PRIMARY KEY (id);


--
-- TOC entry 5099 (class 2606 OID 33994)
-- Name: reports reports_scan_id_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reports
    ADD CONSTRAINT reports_scan_id_key UNIQUE (scan_id);


--
-- TOC entry 5094 (class 2606 OID 33974)
-- Name: risk_scores risk_scores_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.risk_scores
    ADD CONSTRAINT risk_scores_pkey PRIMARY KEY (id);


--
-- TOC entry 5127 (class 2606 OID 34965)
-- Name: scan_endpoints scan_endpoints_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_pkey PRIMARY KEY (id);


--
-- TOC entry 5129 (class 2606 OID 34967)
-- Name: scan_endpoints scan_endpoints_scan_id_url_http_method_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_url_http_method_key UNIQUE (scan_id, url, http_method);


--
-- TOC entry 5103 (class 2606 OID 34014)
-- Name: scan_results scan_results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_results
    ADD CONSTRAINT scan_results_pkey PRIMARY KEY (id);


--
-- TOC entry 5111 (class 2606 OID 34533)
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- TOC entry 5085 (class 2606 OID 33897)
-- Name: traffic_logs traffic_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 5106 (class 2606 OID 34500)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 5088 (class 2606 OID 33933)
-- Name: vulnerabilities vulnerabilities_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vulnerabilities
    ADD CONSTRAINT vulnerabilities_pkey PRIMARY KEY (id);


--
-- TOC entry 5120 (class 1259 OID 34604)
-- Name: idx_activity_logs_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_created_at ON public.activity_logs USING btree (created_at DESC);


--
-- TOC entry 5121 (class 1259 OID 34606)
-- Name: idx_activity_logs_scan_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_scan_created_at ON public.activity_logs USING btree (scan_id, created_at DESC) WHERE (scan_id IS NOT NULL);


--
-- TOC entry 5122 (class 1259 OID 34607)
-- Name: idx_activity_logs_security_events; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_security_events ON public.activity_logs USING btree (created_at DESC) WHERE (level = ANY (ARRAY['warning'::public.log_level, 'error'::public.log_level, 'security'::public.log_level]));


--
-- TOC entry 5123 (class 1259 OID 34605)
-- Name: idx_activity_logs_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_activity_logs_user_created_at ON public.activity_logs USING btree (user_id, created_at DESC) WHERE (user_id IS NOT NULL);


--
-- TOC entry 5143 (class 1259 OID 35167)
-- Name: idx_alert_audit_logs_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_audit_logs_alert_id ON public.alert_audit_logs USING btree (alert_id, created_at);


--
-- TOC entry 5140 (class 1259 OID 35141)
-- Name: idx_alert_notes_alert_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alert_notes_alert_id ON public.alert_notes USING btree (alert_id, created_at);


--
-- TOC entry 5132 (class 1259 OID 35115)
-- Name: idx_alerts_assigned_to; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_assigned_to ON public.alerts USING btree (assigned_to);


--
-- TOC entry 5133 (class 1259 OID 35104)
-- Name: idx_alerts_correlation_key; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_correlation_key ON public.alerts USING btree (correlation_key);


--
-- TOC entry 5134 (class 1259 OID 35107)
-- Name: idx_alerts_last_seen_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_last_seen_at ON public.alerts USING btree (last_seen_at DESC);


--
-- TOC entry 5135 (class 1259 OID 35103)
-- Name: idx_alerts_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_scan_id ON public.alerts USING btree (scan_id);


--
-- TOC entry 5136 (class 1259 OID 35106)
-- Name: idx_alerts_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_severity ON public.alerts USING btree (severity);


--
-- TOC entry 5137 (class 1259 OID 35105)
-- Name: idx_alerts_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_alerts_status ON public.alerts USING btree (status);


--
-- TOC entry 5149 (class 1259 OID 35227)
-- Name: idx_finding_audit_logs_finding_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_finding_audit_logs_finding_id ON public.finding_audit_logs USING btree (finding_id, created_at);


--
-- TOC entry 5146 (class 1259 OID 35201)
-- Name: idx_finding_notes_finding_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_finding_notes_finding_id ON public.finding_notes USING btree (finding_id, created_at);


--
-- TOC entry 5114 (class 1259 OID 34575)
-- Name: idx_findings_cwe_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_cwe_id ON public.findings USING btree (cwe_id) WHERE (cwe_id IS NOT NULL);


--
-- TOC entry 5115 (class 1259 OID 35175)
-- Name: idx_findings_fingerprint; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_fingerprint ON public.findings USING btree (fingerprint);


--
-- TOC entry 5116 (class 1259 OID 34573)
-- Name: idx_findings_scan_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_scan_severity ON public.findings USING btree (scan_id, severity);


--
-- TOC entry 5117 (class 1259 OID 34574)
-- Name: idx_findings_status_severity; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_findings_status_severity ON public.findings USING btree (status, severity);


--
-- TOC entry 5124 (class 1259 OID 34973)
-- Name: idx_scan_endpoints_scan; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_scan ON public.scan_endpoints USING btree (scan_id);


--
-- TOC entry 5125 (class 1259 OID 34974)
-- Name: idx_scan_endpoints_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scan_endpoints_status ON public.scan_endpoints USING btree (scan_id, crawl_status);


--
-- TOC entry 5107 (class 1259 OID 34778)
-- Name: idx_scans_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_status_created_at ON public.scans USING btree (status, created_at DESC);


--
-- TOC entry 5108 (class 1259 OID 34539)
-- Name: idx_scans_user_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_created_at ON public.scans USING btree (user_id, created_at DESC);


--
-- TOC entry 5109 (class 1259 OID 34826)
-- Name: idx_scans_user_status_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_scans_user_status_created_at ON public.scans USING btree (user_id, status, created_at DESC);


--
-- TOC entry 5081 (class 1259 OID 34981)
-- Name: idx_traffic_logs_id_desc; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_id_desc ON public.traffic_logs USING btree (id DESC);


--
-- TOC entry 5082 (class 1259 OID 34980)
-- Name: idx_traffic_logs_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_traffic_logs_scan_id ON public.traffic_logs USING btree (scan_id);


--
-- TOC entry 5091 (class 1259 OID 33959)
-- Name: ix_ai_predictions_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_ai_predictions_id ON public.ai_predictions USING btree (id);


--
-- TOC entry 5095 (class 1259 OID 34000)
-- Name: ix_reports_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_reports_id ON public.reports USING btree (id);


--
-- TOC entry 5092 (class 1259 OID 33980)
-- Name: ix_risk_scores_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_risk_scores_id ON public.risk_scores USING btree (id);


--
-- TOC entry 5100 (class 1259 OID 34021)
-- Name: ix_scan_results_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_id ON public.scan_results USING btree (id);


--
-- TOC entry 5101 (class 1259 OID 34020)
-- Name: ix_scan_results_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scan_results_scan_id ON public.scan_results USING btree (scan_id);


--
-- TOC entry 5083 (class 1259 OID 33898)
-- Name: ix_traffic_logs_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_traffic_logs_id ON public.traffic_logs USING btree (id);


--
-- TOC entry 5086 (class 1259 OID 33939)
-- Name: ix_vulnerabilities_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_vulnerabilities_id ON public.vulnerabilities USING btree (id);


--
-- TOC entry 5104 (class 1259 OID 34501)
-- Name: uq_users_email_lower; Type: INDEX; Schema: public; Owner: postgres
--

CREATE UNIQUE INDEX uq_users_email_lower ON public.users USING btree (lower((email)::text));


--
-- TOC entry 5319 (class 2618 OID 34830)
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
-- TOC entry 5171 (class 2620 OID 35108)
-- Name: alerts alerts_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER alerts_set_updated_at BEFORE UPDATE ON public.alerts FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5170 (class 2620 OID 34611)
-- Name: findings findings_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER findings_set_updated_at BEFORE UPDATE ON public.findings FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5169 (class 2620 OID 34610)
-- Name: scans scans_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER scans_set_updated_at BEFORE UPDATE ON public.scans FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5168 (class 2620 OID 34609)
-- Name: users users_set_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER users_set_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- TOC entry 5154 (class 2606 OID 34599)
-- Name: activity_logs activity_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE SET NULL;


--
-- TOC entry 5155 (class 2606 OID 34594)
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5162 (class 2606 OID 35157)
-- Name: alert_audit_logs alert_audit_logs_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- TOC entry 5163 (class 2606 OID 35162)
-- Name: alert_audit_logs alert_audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_audit_logs
    ADD CONSTRAINT alert_audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5160 (class 2606 OID 35131)
-- Name: alert_notes alert_notes_alert_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_alert_id_fkey FOREIGN KEY (alert_id) REFERENCES public.alerts(id) ON DELETE CASCADE;


--
-- TOC entry 5161 (class 2606 OID 35136)
-- Name: alert_notes alert_notes_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alert_notes
    ADD CONSTRAINT alert_notes_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5157 (class 2606 OID 35110)
-- Name: alerts alerts_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5158 (class 2606 OID 35093)
-- Name: alerts alerts_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5159 (class 2606 OID 35098)
-- Name: alerts alerts_traffic_log_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.alerts
    ADD CONSTRAINT alerts_traffic_log_id_fkey FOREIGN KEY (traffic_log_id) REFERENCES public.traffic_logs(id) ON DELETE SET NULL;


--
-- TOC entry 5166 (class 2606 OID 35217)
-- Name: finding_audit_logs finding_audit_logs_finding_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_audit_logs
    ADD CONSTRAINT finding_audit_logs_finding_id_fkey FOREIGN KEY (finding_id) REFERENCES public.findings(id) ON DELETE CASCADE;


--
-- TOC entry 5167 (class 2606 OID 35222)
-- Name: finding_audit_logs finding_audit_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_audit_logs
    ADD CONSTRAINT finding_audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5164 (class 2606 OID 35196)
-- Name: finding_notes finding_notes_author_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_notes
    ADD CONSTRAINT finding_notes_author_id_fkey FOREIGN KEY (author_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5165 (class 2606 OID 35191)
-- Name: finding_notes finding_notes_finding_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.finding_notes
    ADD CONSTRAINT finding_notes_finding_id_fkey FOREIGN KEY (finding_id) REFERENCES public.findings(id) ON DELETE CASCADE;


--
-- TOC entry 5152 (class 2606 OID 35170)
-- Name: findings findings_assigned_to_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- TOC entry 5153 (class 2606 OID 34568)
-- Name: findings findings_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5156 (class 2606 OID 34968)
-- Name: scan_endpoints scan_endpoints_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scan_endpoints
    ADD CONSTRAINT scan_endpoints_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


--
-- TOC entry 5151 (class 2606 OID 34534)
-- Name: scans scans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE RESTRICT;


--
-- TOC entry 5150 (class 2606 OID 34975)
-- Name: traffic_logs traffic_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.traffic_logs
    ADD CONSTRAINT traffic_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id) ON DELETE CASCADE;


-- Completed on 2026-10-10 05:07:01

--
-- PostgreSQL database dump complete
--

\unrestrict dGTG5CmnT9WIg3qOZ9CsBDPs2t0UHnbHSXq0aiRUc9wPFKY29JvsszW9fjFOmKS


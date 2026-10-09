--
-- PostgreSQL database dump
--

\restrict n1fnRa9cddGmjoVlaVp1Eapr0DlOC03axEcTJtVcOqeEPDVkXJNY6JR48h3NOlg

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

-- Started on 2026-10-03 18:56:30

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
-- TOC entry 863 (class 1247 OID 16536)
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
-- TOC entry 866 (class 1247 OID 16548)
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
-- TOC entry 860 (class 1247 OID 16524)
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
-- TOC entry 857 (class 1247 OID 16517)
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'analyst',
    'viewer'
);


ALTER TYPE public.user_role OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 224 (class 1259 OID 16626)
-- Name: activity_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.activity_logs (
    id bigint NOT NULL,
    user_id uuid,
    scan_id integer,
    level public.log_level NOT NULL,
    action character varying(150) NOT NULL,
    message text NOT NULL,
    ip_address inet,
    user_agent text,
    details jsonb NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.activity_logs OWNER TO postgres;

--
-- TOC entry 223 (class 1259 OID 16625)
-- Name: activity_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.activity_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.activity_logs_id_seq OWNER TO postgres;

--
-- TOC entry 5062 (class 0 OID 0)
-- Dependencies: 223
-- Name: activity_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.activity_logs_id_seq OWNED BY public.activity_logs.id;


--
-- TOC entry 222 (class 1259 OID 16599)
-- Name: findings; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.findings (
    id uuid NOT NULL,
    scan_id integer NOT NULL,
    vulnerability_type character varying(150) NOT NULL,
    title character varying(300) NOT NULL,
    description text,
    severity public.risk_severity NOT NULL,
    cvss_score numeric(3,1),
    cwe_id character varying(20),
    affected_url text,
    parameter_name character varying(200),
    evidence jsonb NOT NULL,
    remediation text,
    status public.finding_status NOT NULL,
    ai_confidence numeric(4,3),
    detected_at timestamp with time zone DEFAULT now() NOT NULL,
    resolved_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.findings OWNER TO postgres;

--
-- TOC entry 221 (class 1259 OID 16576)
-- Name: scans; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.scans (
    id integer NOT NULL,
    user_id uuid,
    target_url text NOT NULL,
    scan_type character varying(100) NOT NULL,
    spider boolean NOT NULL,
    passive boolean NOT NULL,
    active boolean NOT NULL,
    status character varying(50) NOT NULL,
    created_at timestamp without time zone NOT NULL
);


ALTER TABLE public.scans OWNER TO postgres;

--
-- TOC entry 220 (class 1259 OID 16575)
-- Name: scans_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.scans_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.scans_id_seq OWNER TO postgres;

--
-- TOC entry 5063 (class 0 OID 0)
-- Dependencies: 220
-- Name: scans_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.scans_id_seq OWNED BY public.scans.id;


--
-- TOC entry 219 (class 1259 OID 16559)
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    email character varying(320) NOT NULL,
    password_hash text NOT NULL,
    full_name character varying(200),
    role public.user_role NOT NULL,
    is_active boolean NOT NULL,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.users OWNER TO postgres;

--
-- TOC entry 4887 (class 2604 OID 16629)
-- Name: activity_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs ALTER COLUMN id SET DEFAULT nextval('public.activity_logs_id_seq'::regclass);


--
-- TOC entry 4883 (class 2604 OID 16579)
-- Name: scans id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans ALTER COLUMN id SET DEFAULT nextval('public.scans_id_seq'::regclass);


--
-- TOC entry 5056 (class 0 OID 16626)
-- Dependencies: 224
-- Data for Name: activity_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.activity_logs (id, user_id, scan_id, level, action, message, ip_address, user_agent, details, created_at) FROM stdin;
\.


--
-- TOC entry 5054 (class 0 OID 16599)
-- Dependencies: 222
-- Data for Name: findings; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.findings (id, scan_id, vulnerability_type, title, description, severity, cvss_score, cwe_id, affected_url, parameter_name, evidence, remediation, status, ai_confidence, detected_at, resolved_at, created_at, updated_at) FROM stdin;
\.


--
-- TOC entry 5053 (class 0 OID 16576)
-- Dependencies: 221
-- Data for Name: scans; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.scans (id, user_id, target_url, scan_type, spider, passive, active, status, created_at) FROM stdin;
1	\N	https://themangesh.in/	Web Application Scan	t	t	f	queued	2026-09-28 11:23:02.0337
\.


--
-- TOC entry 5051 (class 0 OID 16559)
-- Dependencies: 219
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, email, password_hash, full_name, role, is_active, last_login_at, created_at, updated_at) FROM stdin;
aaebea02-4bb2-4c18-ae91-8f77f4549b80	sayali.test20261004@example.com	$2b$12$I1DvXbBhVM/LCUF3/By4yOueABTGFxy4MaAGBWMpzSpmJREETrV2W	Sayali Test	analyst	t	2026-10-03 01:36:32.110191+05:30	2026-10-03 01:33:50.315955+05:30	2026-10-03 01:33:50.315955+05:30
9017b63e-926a-4ae3-8e35-651741632d9f	sayali.test20261003@example.com	$2b$12$W.dwZdUuEhdOA6G3qCJz3.8NRHg2TaAm7VVptaTF8vvL614GQCMdq	Sayali Test	analyst	t	2026-10-03 10:22:56.33325+05:30	2026-10-03 01:29:15.401956+05:30	2026-10-03 01:29:15.401956+05:30
68d0f5b9-1d89-49f7-aec4-60444e8b04f3	shelavlesayali@gmail.com	$2b$12$A67jV1kBRzB0JEFvoTCqXeIq4VU8G13pmdzzxt3RNVW5ss5w3O4ai	sayali	analyst	t	2026-10-03 15:11:44.005316+05:30	2026-10-03 15:02:30.281605+05:30	2026-10-03 15:02:30.281605+05:30
\.


--
-- TOC entry 5064 (class 0 OID 0)
-- Dependencies: 223
-- Name: activity_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.activity_logs_id_seq', 1, false);


--
-- TOC entry 5065 (class 0 OID 0)
-- Dependencies: 220
-- Name: scans_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.scans_id_seq', 1, true);


--
-- TOC entry 4899 (class 2606 OID 16640)
-- Name: activity_logs activity_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_pkey PRIMARY KEY (id);


--
-- TOC entry 4896 (class 2606 OID 16618)
-- Name: findings findings_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_pkey PRIMARY KEY (id);


--
-- TOC entry 4894 (class 2606 OID 16591)
-- Name: scans scans_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_pkey PRIMARY KEY (id);


--
-- TOC entry 4890 (class 2606 OID 16574)
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- TOC entry 4897 (class 1259 OID 16624)
-- Name: ix_findings_scan_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_findings_scan_id ON public.findings USING btree (scan_id);


--
-- TOC entry 4891 (class 1259 OID 16597)
-- Name: ix_scans_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scans_id ON public.scans USING btree (id);


--
-- TOC entry 4892 (class 1259 OID 16598)
-- Name: ix_scans_user_id; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX ix_scans_user_id ON public.scans USING btree (user_id);


--
-- TOC entry 4902 (class 2606 OID 16646)
-- Name: activity_logs activity_logs_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id);


--
-- TOC entry 4903 (class 2606 OID 16641)
-- Name: activity_logs activity_logs_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.activity_logs
    ADD CONSTRAINT activity_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


--
-- TOC entry 4901 (class 2606 OID 16619)
-- Name: findings findings_scan_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.findings
    ADD CONSTRAINT findings_scan_id_fkey FOREIGN KEY (scan_id) REFERENCES public.scans(id);


--
-- TOC entry 4900 (class 2606 OID 16592)
-- Name: scans scans_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.scans
    ADD CONSTRAINT scans_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id);


-- Completed on 2026-10-03 18:56:30

--
-- PostgreSQL database dump complete
--

\unrestrict n1fnRa9cddGmjoVlaVp1Eapr0DlOC03axEcTJtVcOqeEPDVkXJNY6JR48h3NOlg


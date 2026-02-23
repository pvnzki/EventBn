--
-- PostgreSQL database dump
--

\restrict SjosH8veP4iLe6bX8xwSdczcEjXKxBn55NnekEG8f4VlgCecEQfCEakvfVfclkr

-- Dumped from database version 16.12
-- Dumped by pg_dump version 16.12

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: posts; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.posts VALUES (1, 146, 29, 'hh', 'https://res.cloudinary.com/dbnessuce/image/upload/v1771858737/eventbn/posts/1771858735272_vds0r6l95.jpg', '{https://res.cloudinary.com/dbnessuce/image/upload/v1771858737/eventbn/posts/1771858735272_vds0r6l95.jpg}', '{}', 0, 0, true, '2026-02-23 14:58:58.223', '2026-02-23 14:58:58.223');


--
-- Data for Name: comments; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: comment_likes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: post_likes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: reactions; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: comment_likes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comment_likes_id_seq', 1, false);


--
-- Name: comments_comment_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.comments_comment_id_seq', 1, false);


--
-- Name: post_likes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.post_likes_id_seq', 1, false);


--
-- Name: posts_post_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.posts_post_id_seq', 1, true);


--
-- Name: reactions_reaction_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.reactions_reaction_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--

\unrestrict SjosH8veP4iLe6bX8xwSdczcEjXKxBn55NnekEG8f4VlgCecEQfCEakvfVfclkr


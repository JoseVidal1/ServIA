--
-- PostgreSQL database dump
--

\restrict 016TvijXEQmctIBGg05m3C6VAl5oOtolao6cSyqZlJjZQ7VsscuRBqVPNlsxV91

-- Dumped from database version 17.11 (Debian 17.11-1.pgdg13+2)
-- Dumped by pg_dump version 17.11 (Debian 17.11-1.pgdg13+2)

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
-- Name: auth; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA auth;


--
-- Name: estado_postulacion; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_postulacion AS ENUM (
    'pendiente',
    'aceptada',
    'rechazada',
    'en_espera'
);


--
-- Name: estado_publicacion; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.estado_publicacion AS ENUM (
    'activo',
    'acuerdo',
    'en_progreso',
    'terminado',
    'cancelado',
    'expirado'
);


--
-- Name: nivel_urgencia; Type: TYPE; Schema: public; Owner: -
--

CREATE TYPE public.nivel_urgencia AS ENUM (
    'ahora',
    'hoy',
    'esta semana',
    'no tengo prisa'
);


--
-- Name: uid(); Type: FUNCTION; Schema: auth; Owner: -
--

CREATE FUNCTION auth.uid() RETURNS uuid
    LANGUAGE sql STABLE
    AS $$SELECT NULL::uuid$$;


--
-- Name: crear_cliente_automaticamente(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.crear_cliente_automaticamente() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
BEGIN
    INSERT INTO public.clientes (id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$;


--
-- Name: handle_new_user(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.handle_new_user() RETURNS trigger
    LANGUAGE plpgsql SECURITY DEFINER
    SET search_path TO 'public'
    AS $$
begin
    insert into public.usuarios (
        id,
        nombre_completo,
        telefono,
        ubicacion
    )
    values (
        new.id,
        coalesce(new.raw_user_meta_data->>'nombre_completo', ''),
        new.raw_user_meta_data->>'telefono',
        new.raw_user_meta_data->>'ubicacion'
    );

    return new;
end;
$$;


--
-- Name: set_updated_at(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.set_updated_at() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$;


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    nombre text NOT NULL,
    descripcion text,
    icono text
);


--
-- Name: clientes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.clientes (
    id uuid NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: especialidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.especialidades (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prestador_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: postulaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.postulaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    publicacion_id uuid NOT NULL,
    prestador_id uuid NOT NULL,
    precio_ofertado numeric(10,2) NOT NULL,
    disponibilidad character varying(100) NOT NULL,
    mensaje text NOT NULL,
    estado public.estado_postulacion DEFAULT 'pendiente'::public.estado_postulacion NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL,
    CONSTRAINT postulaciones_precio_ofertado_check CHECK ((precio_ofertado > (0)::numeric))
);


--
-- Name: prestadores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.prestadores (
    id uuid NOT NULL,
    descripcion text,
    disponible boolean DEFAULT true NOT NULL,
    verificado boolean DEFAULT false NOT NULL,
    fecha_creacion timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: publicaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.publicaciones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    descripcion text NOT NULL,
    categoria_id uuid NOT NULL,
    urgencia public.nivel_urgencia NOT NULL,
    usuario_id uuid DEFAULT auth.uid() NOT NULL,
    estado public.estado_publicacion DEFAULT 'activo'::public.estado_publicacion NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    updated_at timestamp with time zone DEFAULT now() NOT NULL
);


--
-- Name: servicios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.servicios (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    prestador_id uuid NOT NULL,
    categoria_id uuid NOT NULL,
    nombre text NOT NULL,
    descripcion text NOT NULL,
    precio_desde numeric(10,2) NOT NULL,
    precio_hasta numeric(10,2) NOT NULL,
    duracion_estimada integer NOT NULL,
    activo boolean DEFAULT false,
    fecha_publicacion timestamp with time zone,
    fecha_creacion timestamp with time zone DEFAULT now()
);


--
-- Name: usuarios; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.usuarios (
    id uuid NOT NULL,
    nombre_completo text NOT NULL,
    telefono text,
    foto_perfil text,
    ubicacion text,
    fecha_registro timestamp with time zone DEFAULT now() NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    hashed_password character varying DEFAULT '$2b$12$Q0bsuD6C1MUpbKIC1Gtd0evarR35asVs3qjH5imhg5UgIigqaOI2i'::character varying NOT NULL,
    email text
);


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.categorias (id, nombre, descripcion, icono) FROM stdin;
b42848e1-c8fd-4ab7-9cc0-21d25f360bda	Limpieza	Servicios de limpieza general y profunda para hogares u oficinas.	cleaning_services
25c52bf4-f66b-4f83-bae9-365075e8546a	Albañilería	Construcción, remodelaciones y reparaciones estructurales.	construction
79ff9223-a11e-448a-b383-88e947de7efe	Pintura	Pintura de interiores, exteriores y acabados.	format_paint
8866df0e-386c-4130-bec1-a5535573a181	Climatización	Instalación y mantenimiento de aire acondicionado y calefacción.	ac_unit
309b7658-ec49-4ed9-8e1d-babef448ae87	Plomería	Fugas, tuberías, grifos, instalaciones sanitarias	ti-droplet
6cdb3be6-7f4b-48d5-8ccb-bcde129a86ed	Electricidad	Instalaciones, cortos, tableros, cableado	ti-bolt
092c10e9-3f3e-430b-bffa-a493f00be823	Carpintería	Muebles, puertas, closets, reparación de madera	ti-hammer
327708fe-3d6a-40dd-a95b-a3010ac9de0d	Cerrajería	Cambio de chapas, llaves, apertura de puertas	ti-key
395845b8-332e-4f95-b686-d6e824a62a78	Jardinería	Poda, diseño de jardines, mantenimiento de áreas verdes	ti-plant-2
a38e04db-de6c-46d1-9639-6e99110b94df	Limpieza del hogar	Limpieza profunda, rutinaria, post obra	ti-spray
43ccdfae-2bbb-4904-9824-b326e9e966b1	Techos e impermeabilización	Goteras, membranas, reparación de tejados	ti-home-2
75597730-d042-4b18-979f-9a5205dde131	Drywall y cielo raso	Instalación y reparación de paneles de yeso	ti-layout-board
8ebe6587-f1f5-4fa8-8ad6-43ba21714d7b	Aire acondicionado	Instalación, mantenimiento, recarga de gas	ti-air-conditioning
f1d3e8cb-6c54-481e-aacc-afa5fd1b88db	Refrigeración	Neveras, congeladores, cuartos fríos	ti-temperature-snow
6017401d-bdd3-4a8e-8834-749e9545c856	Gasfitería	Instalación y reparación de gas domiciliario	ti-flame
6f5ecc04-d60b-481e-9bef-f9f022f75717	Instalación de pisos	Cerámica, porcelanato, laminado, alfombra	ti-layout-grid
b94591be-b28d-42c4-9ad2-9fcd22307e94	Vidriería y aluminio	Ventanas, espejos, estructuras de aluminio	ti-window
c8495666-2db2-4981-a508-fe2671e5b189	Control de plagas	Fumigación, roedores, insectos	ti-bug
bc7ee3e3-5815-4dbf-93ca-ec510ae1767e	Mudanzas	Transporte de muebles, embalaje, cargue	ti-truck
867ce311-05ed-48fe-bcfe-67bd0b28e6d3	Remodelación	Reformas integrales, ampliaciones	ti-tools
717c493a-ca8b-4f88-b451-0d89232cf5d2	Decoración de interiores	Diseño, ambientación, asesoría estética	ti-sofa
c3fd927e-28a2-43aa-91b6-3a7beca24245	Soldadura y estructuras metálicas	Rejas, portones, estructuras	ti-tools-kitchen-2
9e161b76-b6ea-44a4-99e2-aebdf215d93d	Impermeabilización de tanques	Tanques de agua, cisternas	ti-droplet-half-2
9c2f2df7-72e1-48e2-b0bd-d40b84429ba3	Automatización del hogar	Domótica, cámaras, cerraduras inteligentes	ti-smart-home
8936202d-d9f8-4774-bdae-eca37db04a04	Piscinas	Mantenimiento, reparación, limpieza	ti-pool
17d871cf-6507-4149-8206-7f6e8e57be40	Electrodomésticos	Reparación de lavadoras, neveras, estufas	ti-device-desktop
b5e66ffa-abfe-4098-920b-ee9490c26667	Mecánica automotriz a domicilio	Diagnóstico y reparación básica	ti-car
\.


--
-- Data for Name: clientes; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.clientes (id, fecha_creacion) FROM stdin;
e3e7cc9d-4961-4df9-b342-08af266a1c3a	2026-08-25 03:33:32.983311+00
a1b61127-3150-4e7a-a073-9cd0087796fd	2026-08-25 20:41:07.098141+00
2e050a5d-c750-4b7f-a57f-e9e7f2298ee4	2026-08-26 01:57:56.423202+00
\.


--
-- Data for Name: especialidades; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.especialidades (id, prestador_id, categoria_id, fecha_creacion) FROM stdin;
c6441a26-4682-47f7-8768-a42a345e7a32	a1b61127-3150-4e7a-a073-9cd0087796fd	395845b8-332e-4f95-b686-d6e824a62a78	2026-08-25 23:52:17.794358+00
be7f4f64-f453-4211-a6ec-2dfd19e2df75	2e050a5d-c750-4b7f-a57f-e9e7f2298ee4	6cdb3be6-7f4b-48d5-8ccb-bcde129a86ed	2026-08-26 02:02:12.380218+00
5d1a861c-4f69-42e7-83d5-44f160136658	7aedf23c-1d38-4de2-9470-7e1cee624855	6cdb3be6-7f4b-48d5-8ccb-bcde129a86ed	2026-08-26 05:33:33.391793+00
\.


--
-- Data for Name: postulaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.postulaciones (id, publicacion_id, prestador_id, precio_ofertado, disponibilidad, mensaje, estado, created_at, updated_at) FROM stdin;
a3f7d5a7-ac54-40f3-9207-4db9e6a09047	4dbef49d-d219-442c-95ca-eabf40967bd6	7aedf23c-1d38-4de2-9470-7e1cee624855	50000.00	Hoy	Buenas ya mismo podria asistir a solucionar el problema	pendiente	2026-08-26 17:44:13.037816+00	2026-08-26 17:44:13.037816+00
9ae48a75-c12e-463e-86e7-fff4413527b7	4dbef49d-d219-442c-95ca-eabf40967bd6	2e050a5d-c750-4b7f-a57f-e9e7f2298ee4	100000.00	Puedo ir ahora mismo	Cual es ese barrio	pendiente	2026-08-26 15:18:42.874709+00	2026-08-26 17:52:23.750766+00
847354e3-11aa-4c53-b6e3-a512f70b350f	48acf130-709a-4694-acdc-3022bd5923f2	7aedf23c-1d38-4de2-9470-7e1cee624855	120000.00	hoy a las 5	dxfcygubhijn	pendiente	2026-08-26 18:15:02.269831+00	2026-08-26 18:15:02.269831+00
\.


--
-- Data for Name: prestadores; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.prestadores (id, descripcion, disponible, verificado, fecha_creacion) FROM stdin;
a1b61127-3150-4e7a-a073-9cd0087796fd	Tengo 15 años trabajando la jardineria	t	f	2026-08-25 23:52:17.406707+00
2e050a5d-c750-4b7f-a57f-e9e7f2298ee4	Tengo 10 años ejerciendo el oficio de electricista	t	f	2026-08-26 02:02:12.215005+00
7aedf23c-1d38-4de2-9470-7e1cee624855	Soy Juan y probando mi front desde aca	t	f	2026-08-26 05:33:33.160839+00
\.


--
-- Data for Name: publicaciones; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.publicaciones (id, descripcion, categoria_id, urgencia, usuario_id, estado, created_at, updated_at) FROM stdin;
94dd640a-36f9-43e1-a4d7-321a0459f4a6	Pintor de Rejas	79ff9223-a11e-448a-b383-88e947de7efe	hoy	7aedf23c-1d38-4de2-9470-7e1cee624855	activo	2026-08-25 16:00:28.331413+00	2026-08-25 16:00:28.331413+00
c740007e-bf99-41b1-a421-4877cb5d55d8	Tengo una fuga de agua en el lavaplatos	309b7658-ec49-4ed9-8e1d-babef448ae87	ahora	e3e7cc9d-4961-4df9-b342-08af266a1c3a	activo	2026-08-25 05:38:33.262224+00	2026-08-25 05:38:33.262224+00
4dbef49d-d219-442c-95ca-eabf40967bd6	Necesito mover punto eléctrico	6cdb3be6-7f4b-48d5-8ccb-bcde129a86ed	ahora	e3e7cc9d-4961-4df9-b342-08af266a1c3a	activo	2026-08-25 05:53:08.824653+00	2026-08-25 05:53:08.824653+00
d666001b-45e8-499d-8e91-22083b6a91a0	Necesito arreglar un aire en mi casa 	f1d3e8cb-6c54-481e-aacc-afa5fd1b88db	hoy	7aedf23c-1d38-4de2-9470-7e1cee624855	activo	2026-08-26 03:47:49.794954+00	2026-08-26 03:47:49.794954+00
de9fe8b8-6785-49ba-8f4e-258a756d7d44	MANTENIMIENTO TELEVISOR	17d871cf-6507-4149-8206-7f6e8e57be40	esta semana	7aedf23c-1d38-4de2-9470-7e1cee624855	activo	2026-08-26 16:05:18.88298+00	2026-08-26 16:05:18.88298+00
48acf130-709a-4694-acdc-3022bd5923f2	Necesito arreglar el aire	6cdb3be6-7f4b-48d5-8ccb-bcde129a86ed	hoy	7aedf23c-1d38-4de2-9470-7e1cee624855	activo	2026-08-26 18:04:05.464227+00	2026-08-26 18:04:05.464227+00
cbac8697-4d63-44c1-88b3-d46f004670f7	Necesito arreglar	b42848e1-c8fd-4ab7-9cc0-21d25f360bda	ahora	a1b61127-3150-4e7a-a073-9cd0087796fd	activo	2026-09-13 16:42:21.23676+00	2026-09-13 16:42:21.23676+00
\.


--
-- Data for Name: servicios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.servicios (id, prestador_id, categoria_id, nombre, descripcion, precio_desde, precio_hasta, duracion_estimada, activo, fecha_publicacion, fecha_creacion) FROM stdin;
\.


--
-- Data for Name: usuarios; Type: TABLE DATA; Schema: public; Owner: -
--

COPY public.usuarios (id, nombre_completo, telefono, foto_perfil, ubicacion, fecha_registro, activo, hashed_password, email) FROM stdin;
7aedf23c-1d38-4de2-9470-7e1cee624855	Juan Taborda	3015855961	\N	Valledupar	2026-08-21 02:26:26.310601+00	t	$2b$12$Q0bsuD6C1MUpbKIC1Gtd0evarR35asVs3qjH5imhg5UgIigqaOI2i	juantabordaacosta@gmail.com
e3e7cc9d-4961-4df9-b342-08af266a1c3a	Jose David Vidal Quintero	\N	\N	\N	2026-08-25 03:33:32.983311+00	t	$2b$12$Q0bsuD6C1MUpbKIC1Gtd0evarR35asVs3qjH5imhg5UgIigqaOI2i	josevidalquintero2021@gmail.com
a1b61127-3150-4e7a-a073-9cd0087796fd	Abelardo	313538803	\N	la patria milagro	2026-08-25 20:41:07.098141+00	t	$2b$12$Q0bsuD6C1MUpbKIC1Gtd0evarR35asVs3qjH5imhg5UgIigqaOI2i	dcamiloquintero@unicesar.edu.co
2e050a5d-c750-4b7f-a57f-e9e7f2298ee4	Gustavo Petro.	3134567890	\N	Conj. 450 años	2026-08-26 01:57:56.423202+00	t	$2b$12$Q0bsuD6C1MUpbKIC1Gtd0evarR35asVs3qjH5imhg5UgIigqaOI2i	damiancamiloquintero@gmail.com
\.


--
-- Name: categorias categorias_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT categorias_pkey PRIMARY KEY (id);


--
-- Name: clientes clientes_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_pkey PRIMARY KEY (id);


--
-- Name: especialidades especialidades_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_pkey PRIMARY KEY (id);


--
-- Name: especialidades especialidades_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_unique UNIQUE (prestador_id, categoria_id);


--
-- Name: postulaciones postulaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postulaciones
    ADD CONSTRAINT postulaciones_pkey PRIMARY KEY (id);


--
-- Name: prestadores prestadores_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestadores
    ADD CONSTRAINT prestadores_pkey PRIMARY KEY (id);


--
-- Name: publicaciones publicaciones_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicaciones
    ADD CONSTRAINT publicaciones_pkey PRIMARY KEY (id);


--
-- Name: servicios servicios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_pkey PRIMARY KEY (id);


--
-- Name: postulaciones uq_prestador_solicitud; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postulaciones
    ADD CONSTRAINT uq_prestador_solicitud UNIQUE (publicacion_id, prestador_id);


--
-- Name: usuarios usuarios_email_key; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_email_key UNIQUE (email);


--
-- Name: usuarios usuarios_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.usuarios
    ADD CONSTRAINT usuarios_pkey PRIMARY KEY (id);


--
-- Name: idx_servicios_busqueda; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicios_busqueda ON public.servicios USING btree (activo, precio_desde);


--
-- Name: idx_servicios_categoria; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicios_categoria ON public.servicios USING btree (categoria_id);


--
-- Name: idx_servicios_prestador; Type: INDEX; Schema: public; Owner: -
--

CREATE INDEX idx_servicios_prestador ON public.servicios USING btree (prestador_id);


--
-- Name: postulaciones trg_postulaciones_updated_at; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_postulaciones_updated_at BEFORE UPDATE ON public.postulaciones FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();


--
-- Name: usuarios trigger_crear_cliente; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trigger_crear_cliente AFTER INSERT ON public.usuarios FOR EACH ROW EXECUTE FUNCTION public.crear_cliente_automaticamente();


--
-- Name: clientes clientes_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.clientes
    ADD CONSTRAINT clientes_id_fkey FOREIGN KEY (id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: especialidades especialidades_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id) ON DELETE CASCADE;


--
-- Name: especialidades especialidades_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.especialidades
    ADD CONSTRAINT especialidades_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestadores(id) ON DELETE CASCADE;


--
-- Name: postulaciones postulaciones_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.postulaciones
    ADD CONSTRAINT postulaciones_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestadores(id) ON DELETE CASCADE;


--
-- Name: prestadores prestadores_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.prestadores
    ADD CONSTRAINT prestadores_id_fkey FOREIGN KEY (id) REFERENCES public.usuarios(id) ON DELETE CASCADE;


--
-- Name: publicaciones publicaciones_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicaciones
    ADD CONSTRAINT publicaciones_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id);


--
-- Name: publicaciones publicaciones_usuario_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.publicaciones
    ADD CONSTRAINT publicaciones_usuario_id_fkey FOREIGN KEY (usuario_id) REFERENCES public.usuarios(id);


--
-- Name: servicios servicios_categoria_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_categoria_id_fkey FOREIGN KEY (categoria_id) REFERENCES public.categorias(id) ON DELETE RESTRICT;


--
-- Name: servicios servicios_prestador_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.servicios
    ADD CONSTRAINT servicios_prestador_id_fkey FOREIGN KEY (prestador_id) REFERENCES public.prestadores(id) ON DELETE CASCADE;


--
-- Name: servicios Servicios activos son públicos; Type: POLICY; Schema: public; Owner: -
--

CREATE POLICY "Servicios activos son públicos" ON public.servicios FOR SELECT USING ((activo = true));


--
-- Name: clientes; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

--
-- Name: servicios; Type: ROW SECURITY; Schema: public; Owner: -
--

ALTER TABLE public.servicios ENABLE ROW LEVEL SECURITY;

--
-- PostgreSQL database dump complete
--

\unrestrict 016TvijXEQmctIBGg05m3C6VAl5oOtolao6cSyqZlJjZQ7VsscuRBqVPNlsxV91


-- Esquema de SpotMarket para Supabase.
-- Ejecutar completo en el SQL Editor de un proyecto nuevo.
-- Los datos de prueba requieren que exista la cuenta vendedor@spotmarket.com con rol 'vendedor'.

-- Roles de la aplicación
create type public.rol_usuario as enum ('administrador', 'vendedor', 'cliente');

-- Perfil asociado a cada usuario de auth.users
create table public.perfiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nombre text not null,
  correo text not null,
  rol public.rol_usuario not null default 'cliente',
  creado_en timestamptz not null default now()
);

alter table public.perfiles enable row level security;

-- Verifica si el usuario actual es administrador.
-- security definer evita recursión con las políticas de la propia tabla.
create or replace function public.es_admin()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfiles
    where id = auth.uid() and rol = 'administrador'
  );
$$;

create policy "Usuario lee su propio perfil"
  on public.perfiles for select
  using (auth.uid() = id);

create policy "Administrador lee todos los perfiles"
  on public.perfiles for select
  using (public.es_admin());

create policy "Administrador actualiza perfiles"
  on public.perfiles for update
  using (public.es_admin());

-- Crea el perfil al registrarse. El rol siempre inicia como 'cliente'
-- y no se toma de los metadatos enviados por el cliente.
create or replace function public.crear_perfil()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.perfiles (id, nombre, correo)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'nombre', 'Usuario'),
    new.email
  );
  return new;
end;
$$;

create trigger al_crear_usuario
  after insert on auth.users
  for each row execute function public.crear_perfil();


-- Verifica si el usuario actual es vendedor.
create or replace function public.es_vendedor()
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.perfiles
    where id = auth.uid() and rol = 'vendedor'
  );
$$;

create table public.productos (
  id uuid primary key default gen_random_uuid(),
  vendedor_id uuid not null references public.perfiles (id) on delete cascade,
  vendedor_nombre text not null,
  titulo text not null,
  descripcion text not null default '',
  precio numeric(10, 2) not null check (precio >= 0),
  categoria text not null default 'general',
  imagen_url text,
  latitud double precision not null,
  longitud double precision not null,
  estado text not null default 'activo' check (estado in ('activo', 'vendido', 'oculto')),
  creado_en timestamptz not null default now()
);

create table public.favoritos (
  usuario_id uuid not null references public.perfiles (id) on delete cascade,
  producto_id uuid not null references public.productos (id) on delete cascade,
  creado_en timestamptz not null default now(),
  primary key (usuario_id, producto_id)
);

alter table public.productos enable row level security;
alter table public.favoritos enable row level security;

-- Productos
create policy "Ver productos activos, propios o todos si es admin"
  on public.productos for select
  using (estado = 'activo' or vendedor_id = auth.uid() or public.es_admin());

create policy "Vendedor publica sus productos"
  on public.productos for insert
  with check (vendedor_id = auth.uid() and public.es_vendedor());

create policy "Dueño o admin edita productos"
  on public.productos for update
  using (vendedor_id = auth.uid() or public.es_admin());

create policy "Dueño o admin elimina productos"
  on public.productos for delete
  using (vendedor_id = auth.uid() or public.es_admin());

-- Favoritos
create policy "Usuario gestiona sus favoritos"
  on public.favoritos for all
  using (usuario_id = auth.uid())
  with check (usuario_id = auth.uid());

-- Permisos de la Data API (las políticas RLS siguen aplicando).
grant select, insert, update, delete on public.productos to authenticated;
grant select, insert, delete on public.favoritos to authenticated;

-- Datos de prueba: 5 productos en San Luis Potosí (ajustar coordenadas si se desea).
insert into public.productos
  (vendedor_id, vendedor_nombre, titulo, descripcion, precio, categoria, latitud, longitud)
select id, nombre, v.titulo, v.descripcion, v.precio, v.categoria, v.lat, v.lng
from public.perfiles,
  (values
    ('Bicicleta de montaña', 'Rodada 29, buen estado.', 3500, 'deportes', 22.1511, -100.9760),
    ('Laptop usada', '8 GB de RAM, 256 GB SSD.', 5200, 'electronica', 22.1385, -101.0100),
    ('Sillón individual', 'Color gris, sin manchas.', 1200, 'hogar', 22.1450, -101.0000),
    ('Guitarra acústica', 'Incluye funda.', 1800, 'musica', 22.1600, -100.9900),
    ('Escritorio de madera', 'Con dos cajones.', 900, 'hogar', 22.1300, -101.0200)
  ) as v (titulo, descripcion, precio, categoria, lat, lng)
where correo = 'vendedor@spotmarket.com';
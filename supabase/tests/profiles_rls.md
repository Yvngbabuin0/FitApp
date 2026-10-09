# Comprobación manual de RLS en `profiles`

Objetivo: verificar que cada usuario solo ve y modifica su propia fila de
`profiles`.

## Pasos

1. Crear **dos usuarios de prueba** (A y B) con el provider Email en Supabase.
   Al crearse, el trigger `on_auth_user_created` inserta su fila en `profiles`.
2. Con las credenciales de **A** (sesión iniciada en la tabla del editor o vía
   `anon key` + token de A):

   ```sql
   select * from public.profiles;
   ```

   Resultado esperado: **solo la fila de A**.

3. Intentar actualizar la fila de **B** con el token de A:

   ```sql
   update public.profiles set display_name = 'hackeado' where id = '<id de B>';
   ```

   Resultado esperado: **0 filas afectadas** (no hay error, pero no cambia nada).

4. Repetir los pasos 2–3 con el usuario B.

## Resultado

(Anotar aquí la fecha, quién lo ejecutó y qué se observó)

- Fecha:
- Usuario A id:
- Usuario B id:
- select con token A → filas devueltas:
- update fila de B con token A → filas afectadas:
- Comentarios:
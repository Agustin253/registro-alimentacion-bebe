// Configuración de la sincronización (Supabase).
// Si se dejan vacíos, la app funciona igual pero sin cuentas: los datos quedan solo en cada teléfono.
// La "anon key" (o "publishable key") es pública por diseño: la seguridad la dan las reglas RLS de supabase/schema.sql.
window.RAB_CONFIG = {
  supabaseUrl: "",
  supabaseAnonKey: ""
};

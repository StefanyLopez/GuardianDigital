-- ─────────────────────────────────────────────
-- GUARDIAN DIGITAL KIDS — Supabase SQL Setup
-- Ejecuta este script en el SQL Editor de Supabase
-- En orden: primero tablas, luego RLS, luego datos semilla
-- ─────────────────────────────────────────────

-- ── Extensión para UUIDs
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────
-- TABLA: profiles (perfiles de menores)
-- Una familia puede tener hasta 4 perfiles
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS profiles (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  family_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name             TEXT NOT NULL,
  age_range        TEXT NOT NULL CHECK (age_range IN ('8-12', '13-17')),
  avatar_id        INT NOT NULL DEFAULT 0,
  goals            TEXT[] DEFAULT '{}',
  autonomy_level   INT NOT NULL DEFAULT 1 CHECK (autonomy_level BETWEEN 1 AND 5),
  streak_days      INT NOT NULL DEFAULT 0,
  last_active      TIMESTAMPTZ DEFAULT now(),
  visibility_config JSONB DEFAULT '{"share_score": true, "share_streak": true, "share_alerts": true}',
  created_at       TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────
-- TABLA: events (registro de comportamiento)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  type         TEXT NOT NULL,
  -- tipos: 'session', 'intervention_shown', 'intervention_attended',
  --        'intervention_ignored', 'challenge_accept', 'challenge_complete',
  --        'night_usage', 'push_sent', 'push_tapped'
  value        NUMERIC,
  metadata     JSONB DEFAULT '{}',
  created_at   TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────
-- TABLA: challenges (catálogo de retos)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS challenges (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  age_range   TEXT, -- NULL = aplica a todos
  duration    INT NOT NULL DEFAULT 3, -- días
  points      INT NOT NULL DEFAULT 10,
  category    TEXT NOT NULL,
  -- categorías: 'offline', 'mindfulness', 'social', 'sleep', 'focus'
  created_at  TIMESTAMPTZ DEFAULT now()
);

-- ─────────────────────────────────────────────
-- TABLA: challenge_progress
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS challenge_progress (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id   UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  challenge_id UUID NOT NULL REFERENCES challenges(id),
  status       TEXT NOT NULL DEFAULT 'active',
  -- estados: 'active', 'completed', 'expired', 'skipped'
  started_at   TIMESTAMPTZ DEFAULT now(),
  completed_at TIMESTAMPTZ,
  UNIQUE(profile_id, challenge_id, started_at)
);

-- ─────────────────────────────────────────────
-- TABLA: achievements (catálogo de insignias)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS achievements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title       TEXT NOT NULL,
  description TEXT NOT NULL,
  emoji       TEXT NOT NULL DEFAULT '🏅',
  condition   TEXT NOT NULL
  -- condiciones: 'first_chat', 'streak_7', 'streak_30', 'challenge_1',
  --              'challenge_5', 'night_free_3', 'offline_5', 'goal_reached'
);

-- ─────────────────────────────────────────────
-- TABLA: achievement_unlocks
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS achievement_unlocks (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  achievement_id UUID NOT NULL REFERENCES achievements(id),
  unlocked_at    TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, achievement_id)
);

-- ─────────────────────────────────────────────
-- TABLA: wellness_scores (puntuación semanal)
-- ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS wellness_scores (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  week_start       DATE NOT NULL,
  score            NUMERIC(3,1) DEFAULT 0,
  challenges_done  INT DEFAULT 0,
  streak_max       INT DEFAULT 0,
  interventions    JSONB DEFAULT '{"triggered": 0, "attended": 0, "ignored": 0}',
  summary_text     TEXT, -- texto generado para el cuidador
  created_at       TIMESTAMPTZ DEFAULT now(),
  UNIQUE(profile_id, week_start)
);

-- ─────────────────────────────────────────────
-- ROW LEVEL SECURITY (RLS)
-- Cada familia solo ve sus propios datos
-- ─────────────────────────────────────────────

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_progress ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievement_unlocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE wellness_scores ENABLE ROW LEVEL SECURITY;

-- Profiles: solo el dueño de la familia puede ver/editar
CREATE POLICY "family_owns_profiles" ON profiles
  FOR ALL USING (family_id = auth.uid());

-- Events: solo perfiles de la familia autenticada
CREATE POLICY "family_owns_events" ON events
  FOR ALL USING (
    profile_id IN (
      SELECT id FROM profiles WHERE family_id = auth.uid()
    )
  );

-- Challenge progress
CREATE POLICY "family_owns_progress" ON challenge_progress
  FOR ALL USING (
    profile_id IN (
      SELECT id FROM profiles WHERE family_id = auth.uid()
    )
  );

-- Achievement unlocks
CREATE POLICY "family_owns_achievements" ON achievement_unlocks
  FOR ALL USING (
    profile_id IN (
      SELECT id FROM profiles WHERE family_id = auth.uid()
    )
  );

-- Wellness scores
CREATE POLICY "family_owns_wellness" ON wellness_scores
  FOR ALL USING (
    profile_id IN (
      SELECT id FROM profiles WHERE family_id = auth.uid()
    )
  );

-- Challenges y achievements son públicos (solo lectura)
ALTER TABLE challenges ENABLE ROW LEVEL SECURITY;
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "challenges_public_read" ON challenges FOR SELECT USING (true);
CREATE POLICY "achievements_public_read" ON achievements FOR SELECT USING (true);

-- ─────────────────────────────────────────────
-- ÍNDICES DE RENDIMIENTO
--
-- El más crítico: idx_profiles_family_id resuelve el subquery IN (...)
-- que usan TODAS las políticas RLS. Sin él, cada row scan en events,
-- challenge_progress, achievement_unlocks y wellness_scores ejecuta
-- un seq scan sobre profiles. Con él, es un index scan O(log n).
-- ─────────────────────────────────────────────

-- Resuelve el subquery de RLS en todas las tablas secundarias
CREATE INDEX IF NOT EXISTS idx_profiles_family_id
  ON profiles(family_id);

-- StatsScreen: filtro por perfil + orden por semana descendente
CREATE INDEX IF NOT EXISTS idx_wellness_profile_week
  ON wellness_scores(profile_id, week_start DESC);

-- AchievementService + trigger de wellness: eventos por perfil y fecha
CREATE INDEX IF NOT EXISTS idx_events_profile_created
  ON events(profile_id, created_at DESC);

-- Consultas por tipo de evento (session, challenge_complete, night_usage…)
CREATE INDEX IF NOT EXISTS idx_events_profile_type
  ON events(profile_id, type);

-- Challenge progress: filtros por perfil y estado ('active', 'completed'…)
CREATE INDEX IF NOT EXISTS idx_challenge_progress_profile_status
  ON challenge_progress(profile_id, status);

-- Achievement unlocks: queries WHERE profile_id = X (UNIQUE cubre profile+achievement,
-- este índice cubre consultas que solo filtran por profile_id)
CREATE INDEX IF NOT EXISTS idx_achievement_unlocks_profile
  ON achievement_unlocks(profile_id);

-- ─────────────────────────────────────────────
-- FUNCIÓN + TRIGGER: recalcular wellness_score
--
-- Se ejecuta AFTER INSERT en events. Recalcula automáticamente el
-- score semanal del perfil afectado usando solo datos de Postgres,
-- sin consumir Edge Function invocations del plan gratuito.
-- ─────────────────────────────────────────────

CREATE OR REPLACE FUNCTION recalculate_wellness_score()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
  v_week_start    DATE;
  v_sessions      INT;
  v_challenges    INT;
  v_night         INT;
  v_int_triggered INT;
  v_int_attended  INT;
  v_int_ignored   INT;
  v_streak_max    INT;
  v_score         NUMERIC(3,1);
BEGIN
  -- Lunes de la semana ISO del evento insertado
  v_week_start := date_trunc('week', NEW.created_at)::DATE;

  -- Contar eventos de esta semana para el perfil
  SELECT
    COUNT(*) FILTER (WHERE type = 'session'),
    COUNT(*) FILTER (WHERE type = 'challenge_complete'),
    COUNT(*) FILTER (WHERE type = 'night_usage'),
    COUNT(*) FILTER (WHERE type = 'intervention_shown'),
    COUNT(*) FILTER (WHERE type = 'intervention_attended'),
    COUNT(*) FILTER (WHERE type = 'intervention_ignored')
  INTO
    v_sessions, v_challenges, v_night,
    v_int_triggered, v_int_attended, v_int_ignored
  FROM events
  WHERE profile_id = NEW.profile_id
    AND created_at >= v_week_start
    AND created_at <  v_week_start + INTERVAL '7 days';

  -- Racha actual del perfil (snapshot del momento)
  SELECT COALESCE(streak_days, 0)
  INTO v_streak_max
  FROM profiles
  WHERE id = NEW.profile_id;

  -- Fórmula de score (0–10)
  -- Actividad base + retos completados - penalizaciones + bonus racha
  v_score := LEAST(10.0,
    (v_sessions      * 0.5 )   -- actividad semanal
    + (v_challenges  * 1.5 )   -- retos completados
    - (v_night       * 1.0 )   -- penaliza uso nocturno
    + (v_int_attended * 0.5)   -- intervenciones atendidas
    - (v_int_ignored  * 0.25)  -- ignoradas restan menos
    + LEAST(v_streak_max * 0.1, 2.0)  -- bonus racha, cap 2 puntos
  );
  v_score := GREATEST(0.0, v_score);

  -- Upsert: crea la fila si no existe, actualiza si ya existe
  INSERT INTO wellness_scores (
    profile_id,
    week_start,
    score,
    challenges_done,
    streak_max,
    interventions
  ) VALUES (
    NEW.profile_id,
    v_week_start,
    v_score,
    v_challenges,
    v_streak_max,
    jsonb_build_object(
      'triggered', v_int_triggered,
      'attended',  v_int_attended,
      'ignored',   v_int_ignored
    )
  )
  ON CONFLICT (profile_id, week_start) DO UPDATE SET
    score           = EXCLUDED.score,
    challenges_done = EXCLUDED.challenges_done,
    streak_max      = EXCLUDED.streak_max,
    interventions   = EXCLUDED.interventions;

  RETURN NEW;
END;
$$;

-- Trigger: se dispara después de cada INSERT en events
CREATE OR REPLACE TRIGGER trg_wellness_on_event
  AFTER INSERT ON events
  FOR EACH ROW
  EXECUTE FUNCTION recalculate_wellness_score();

-- ─────────────────────────────────────────────
-- DATOS SEMILLA — Retos iniciales
-- ─────────────────────────────────────────────
INSERT INTO challenges (title, description, age_range, duration, points, category) VALUES
  ('Noche sin pantallas', 'Esta noche, apaga el celular a las 9pm y cuéntame cómo te fue mañana.', NULL, 1, 15, 'sleep'),
  ('20 minutos offline', 'Haz 20 minutos de algo que te guste que no sea pantalla. ¿Qué elegirías?', NULL, 1, 10, 'offline'),
  ('Semana de despertares', 'Durante 3 días, no mires el celular los primeros 10 minutos del día.', NULL, 3, 25, 'mindfulness'),
  ('Momento en familia', 'Propón hacer algo con tu familia sin celulares presentes.', NULL, 2, 20, 'social'),
  ('El reto del scroll', 'Cuando sientas ganas de abrir redes, escribe primero una cosa buena del día.', '13-17', 3, 20, 'mindfulness'),
  ('Misión libro', 'Lee 15 minutos de algo que te guste, aunque sea un cómic.', '8-12', 2, 15, 'offline'),
  ('Sin celular al dormir', 'Deja el celular fuera de tu cuarto 3 noches seguidas.', NULL, 3, 30, 'sleep'),
  ('Descubridor de hobbies', 'Prueba algo nuevo offline esta semana y cuéntame qué tal.', NULL, 7, 35, 'offline');

-- ─────────────────────────────────────────────
-- DATOS SEMILLA — Insignias
-- ─────────────────────────────────────────────
INSERT INTO achievements (title, description, emoji, condition) VALUES
  ('Primera charla', 'Tuviste tu primera conversación con Luma.', '💬', 'first_chat'),
  ('Racha de 7 días', 'Usaste Guardian Digital 7 días seguidos.', '🔥', 'streak_7'),
  ('Racha de 30 días', '¡30 días! Eso es compromiso de verdad.', '⚡', 'streak_30'),
  ('Primer reto', 'Completaste tu primer reto de Luma.', '🎯', 'challenge_1'),
  ('Cinco retos', 'Cinco retos completados. ¡Eres imparable!', '🏆', 'challenge_5'),
  ('3 noches libres', 'Tres noches sin pantallas tardías. Tu cerebro te lo agradece.', '🌙', 'night_free_3'),
  ('Explorador offline', 'Completaste 5 actividades fuera de pantalla.', '🌿', 'offline_5'),
  ('Capitán del tiempo', 'Alcanzaste el nivel máximo de autonomía.', '🚀', 'autonomy_5');

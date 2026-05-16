-- ============================================================
-- 오륜미네랄 — Supabase Database Setup
-- 실행 방법: Supabase Dashboard → SQL Editor → 새 쿼리 → 아래 전체 붙여넣기 → Run
-- ============================================================

-- 1) 체험 사례 테이블
create table if not exists public.cases (
  id              uuid primary key default gen_random_uuid(),
  created_at      timestamptz default now(),
  author_name     text default '익명',
  start_weight    numeric,
  end_weight      numeric,
  condition_score integer check (condition_score between 1 and 10),
  one_line        text not null,
  detail          text,
  tag             text default 'BODY'
);

-- 2) 1일 무료체험 신청 테이블
create table if not exists public.trial_signups (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz default now(),
  email       text not null
);

-- 3) Row Level Security 활성화
alter table public.cases enable row level security;
alter table public.trial_signups enable row level security;

-- 4) 정책: 누구나 후기 읽기 가능 (공개 데이터)
drop policy if exists "Anyone can read cases" on public.cases;
create policy "Anyone can read cases"
  on public.cases for select
  using (true);

-- 5) 정책: 누구나 후기 작성 가능
drop policy if exists "Anyone can insert cases" on public.cases;
create policy "Anyone can insert cases"
  on public.cases for insert
  with check (true);

-- 6) 정책: 누구나 체험 신청 가능 (단, 읽기는 막힘 - 개인정보 보호)
drop policy if exists "Anyone can insert trial signups" on public.trial_signups;
create policy "Anyone can insert trial signups"
  on public.trial_signups for insert
  with check (true);

-- 7) 통계 뷰 (실시간 누적 계산)
create or replace view public.case_stats as
select
  count(*)::int                                              as total_cases,
  round(avg(condition_score)::numeric, 2)                    as avg_condition,
  round(avg(end_weight - start_weight)::numeric, 2)          as avg_weight_change,
  count(*) filter (where end_weight - start_weight < 0)::int as weight_loss_count,
  round(
    (count(*) filter (where condition_score >= 7)::numeric
      / nullif(count(condition_score), 0)) * 100,
    0
  )::int                                                     as condition_improvement_pct
from public.cases;

-- 8) 뷰 읽기 권한 부여
grant select on public.case_stats to anon, authenticated;

-- 9) 빠른 조회를 위한 인덱스
create index if not exists idx_cases_created_at on public.cases (created_at desc);

-- ============================================================
-- 완료! 아래 쿼리로 테스트:
--   select * from public.cases;
--   select * from public.case_stats;
-- ============================================================

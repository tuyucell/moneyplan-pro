-- Remove redundant PL/pgSQL integer loop declarations from the already-created
-- functions. Integer FOR loops declare their loop variable automatically.
do $$
declare
  v_function regprocedure;
  v_definition text;
begin
  foreach v_function in array array[
    'public.analyze_purchase_decision(numeric,integer,numeric,numeric)'::regprocedure,
    'public.calculate_financial_pilot(uuid,integer,numeric,integer,numeric)'::regprocedure
  ] loop
    select pg_get_functiondef(v_function) into v_definition;
    v_definition := regexp_replace(
      v_definition,
      '[[:space:]]+i integer;[[:space:]]+begin',
      chr(10) || 'begin',
      'g'
    );
    execute v_definition;
  end loop;
end;
$$;

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 05/11/2010 14:53
-- CHANGE REASON: [ALERT-137811] ALERT_75390 Possibilidade do médico hospital encaminhar o pedido para o administrativo hospital

--1- criacao de tabela de backup
CREATE TABLE wf_transition_bck AS 
 SELECT *
   FROM wf_transition;

--2- alteracoes a tabela
alter table WF_TRANSITION drop column CODE_TRANSITION;

alter table WF_TRANSITION add ID_WORKFLOW_ACTION NUMBER(24);
alter table WF_TRANSITION add ICON VARCHAR2(200);
alter table WF_TRANSITION add FLG_AUTO_TRANSITION VARCHAR2(1) default 'N' not null;

COMMENT ON COLUMN WF_TRANSITION.ID_WORKFLOW_ACTION IS 'Action identifier';
COMMENT ON COLUMN WF_TRANSITION.ICON IS 'Icon transition';
comment on column WF_TRANSITION.FLG_AUTO_TRANSITION is 'Is transition automatic? Y - yes, N - no';

--3- script de migracao de dados
DECLARE
    CURSOR c_action IS
        SELECT id_status_begin, id_status_end, w.ID_WORKFLOW_ACTION
          FROM ref_wf_actions r
          JOIN wf_workflow_action w ON w.internal_name = r.action;

    TYPE t_ibt_action_int IS TABLE OF wf_workflow_action.ID_WORKFLOW_ACTION%TYPE INDEX BY PLS_INTEGER;
    TYPE t_ibt_action IS TABLE OF t_ibt_action_int INDEX BY PLS_INTEGER;
    l_action t_ibt_action;

    l_error VARCHAR2(1000 CHAR);

    CURSOR c_transition IS
        SELECT *
          FROM wf_transition
          where ID_WORKFLOW_ACTION is null;

    TYPE t_transition IS TABLE OF c_transition%ROWTYPE;
    l_tab_transition t_transition;
    l_ID_WORKFLOW_ACTION      wf_transition.ID_WORKFLOW_ACTION%TYPE;

BEGIN

    --------------------------------
    -- obter actions para cada estado
    l_error := 'FOR i IN c_action';
    FOR i IN c_action
    LOOP
        l_error := 'BEG=' || i.id_status_begin || ' END=' || i.id_status_end || ' ACT=' || i.ID_WORKFLOW_ACTION;
        l_action(i.id_status_begin)(i.id_status_end) := i.ID_WORKFLOW_ACTION;
    END LOOP;

    -- accao de criacao de um pedido
    l_action(1)(2) := 1; -- NEW
    l_action(4)(9) := 8;
    
    --------------------------------
    -- preencher a coluna ID_WORKFLOW_ACTION
    
    -- CIRCLE
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 28
     WHERE id_status_end = 23;
     
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 27
     WHERE id_status_end = 24;
    
    -- SUPPLIES
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 29
     WHERE id_workflow = 7;
    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 8
     WHERE id_workflow = 11
       AND id_status_begin = 3
       AND id_status_end = 9;
     
    -- TR    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 30
     WHERE id_status_end = 44;
    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 31
     WHERE id_status_end = 45;
     
     UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 32
     WHERE id_status_end = 46;
      
     UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 33
     WHERE id_status_end = 47;

    -- restante
    l_error := 'OPEN c_transition';
    OPEN c_transition;
    FETCH c_transition BULK COLLECT
        INTO l_tab_transition;
    CLOSE c_transition;

    l_error := 'FOR i in 1..' || l_tab_transition.COUNT || ' LOOP';
    FOR i IN 1 .. l_tab_transition.COUNT
    LOOP
    
        l_error := 'BEG=' || l_tab_transition(i).id_status_begin || ' END=' || l_tab_transition(i).id_status_end;
        l_ID_WORKFLOW_ACTION := l_action(l_tab_transition(i).id_status_begin) (l_tab_transition(i).id_status_end);
    
        l_error := 'l_ID_WORKFLOW_ACTION=' || l_ID_WORKFLOW_ACTION;
        UPDATE wf_transition w
           SET ID_WORKFLOW_ACTION = l_ID_WORKFLOW_ACTION
         WHERE w.id_workflow = l_tab_transition(i).id_workflow
           AND w.id_status_begin = l_tab_transition(i).id_status_begin
           AND w.id_status_end = l_tab_transition(i).id_status_end;
    
    END LOOP;

END;
/

--4- ddl final
alter table WF_TRANSITION modify ID_WORKFLOW_ACTION not null;

alter table WF_TRANSITION drop constraint WTS_PK cascade;
drop index WTS_PK;

alter table WF_TRANSITION add constraint WTS_PK primary key (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION);
CREATE UNIQUE INDEX WTS_PK ON WF_TRANSITION (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION);

alter table WF_TRANSITION add constraint WTS_WWN_FK foreign key (ID_WORKFLOW_ACTION) references WF_WORKFLOW_ACTION (ID_WORKFLOW_ACTION);

ALTER INDEX WTS_PK rebuild tablespace INDEX_M;
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 24/11/2010 12:06
-- CHANGE REASON: [ALERT-137811] 

--1- criacao de tabela de backup
CREATE TABLE wf_transition_bck AS 
 SELECT *
   FROM wf_transition;

--2- alteracoes a tabela
alter table WF_TRANSITION drop column CODE_TRANSITION;

alter table WF_TRANSITION add ID_WORKFLOW_ACTION NUMBER(24);
alter table WF_TRANSITION add ICON VARCHAR2(200);
alter table WF_TRANSITION add FLG_AUTO_TRANSITION VARCHAR2(1) default 'N' not null;

COMMENT ON COLUMN WF_TRANSITION.ID_WORKFLOW_ACTION IS 'Action identifier';
COMMENT ON COLUMN WF_TRANSITION.ICON IS 'Icon transition';
comment on column WF_TRANSITION.FLG_AUTO_TRANSITION is 'Is transition automatic? Y - yes, N - no';

--3- script de migracao de dados
DECLARE
    CURSOR c_action IS
        SELECT id_status_begin, id_status_end, w.ID_WORKFLOW_ACTION
          FROM ref_wf_actions r
          JOIN wf_workflow_action w ON w.internal_name = r.action;

    TYPE t_ibt_action_int IS TABLE OF wf_workflow_action.ID_WORKFLOW_ACTION%TYPE INDEX BY PLS_INTEGER;
    TYPE t_ibt_action IS TABLE OF t_ibt_action_int INDEX BY PLS_INTEGER;
    l_action t_ibt_action;

    l_error VARCHAR2(1000 CHAR);

    CURSOR c_transition IS
        SELECT *
          FROM wf_transition
          where ID_WORKFLOW_ACTION is null;

    TYPE t_transition IS TABLE OF c_transition%ROWTYPE;
    l_tab_transition t_transition;
    l_ID_WORKFLOW_ACTION      wf_transition.ID_WORKFLOW_ACTION%TYPE;

BEGIN

    --------------------------------
    -- obter actions para cada estado
    l_error := 'FOR i IN c_action';
    FOR i IN c_action
    LOOP
        l_error := 'BEG=' || i.id_status_begin || ' END=' || i.id_status_end || ' ACT=' || i.ID_WORKFLOW_ACTION;
        l_action(i.id_status_begin)(i.id_status_end) := i.ID_WORKFLOW_ACTION;
    END LOOP;

    -- accao de criacao de um pedido
    l_action(1)(2) := 1; -- NEW
    l_action(4)(9) := 8;
    
    --------------------------------
    -- preencher a coluna ID_WORKFLOW_ACTION
    
    -- CIRCLE
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 28
     WHERE id_status_end = 23;
     
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 27
     WHERE id_status_end = 24;
    
    -- SUPPLIES
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 29
     WHERE id_workflow = 7;
    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 8
     WHERE id_workflow = 11
       AND id_status_begin = 3
       AND id_status_end = 9;
     
    -- TR    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 30
     WHERE id_status_end = 44;
    
    UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 31
     WHERE id_status_end = 45;
     
     UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 32
     WHERE id_status_end = 46;
      
     UPDATE wf_transition w
       SET ID_WORKFLOW_ACTION = 33
     WHERE id_status_end = 47;

    -- restante
    l_error := 'OPEN c_transition';
    OPEN c_transition;
    FETCH c_transition BULK COLLECT
        INTO l_tab_transition;
    CLOSE c_transition;

    l_error := 'FOR i in 1..' || l_tab_transition.COUNT || ' LOOP';
    FOR i IN 1 .. l_tab_transition.COUNT
    LOOP
    
        l_error := 'BEG=' || l_tab_transition(i).id_status_begin || ' END=' || l_tab_transition(i).id_status_end;
        l_ID_WORKFLOW_ACTION := l_action(l_tab_transition(i).id_status_begin) (l_tab_transition(i).id_status_end);
    
        l_error := 'l_ID_WORKFLOW_ACTION=' || l_ID_WORKFLOW_ACTION;
        UPDATE wf_transition w
           SET ID_WORKFLOW_ACTION = l_ID_WORKFLOW_ACTION
         WHERE w.id_workflow = l_tab_transition(i).id_workflow
           AND w.id_status_begin = l_tab_transition(i).id_status_begin
           AND w.id_status_end = l_tab_transition(i).id_status_end;
    
    END LOOP;

END;
/

--4- ddl final
alter table WF_TRANSITION modify ID_WORKFLOW_ACTION not null;

alter table WF_TRANSITION drop constraint WTS_PK cascade;
drop index WTS_PK;

alter table WF_TRANSITION add constraint WTS_PK primary key (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION);
--CREATE UNIQUE INDEX WTS_PK ON WF_TRANSITION (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION);

alter table WF_TRANSITION add constraint WTS_WWN_FK foreign key (ID_WORKFLOW_ACTION) references WF_WORKFLOW_ACTION (ID_WORKFLOW_ACTION);

ALTER INDEX WTS_PK rebuild tablespace INDEX_M;
-- CHANGE END: Ana Monteiro
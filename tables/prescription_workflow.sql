-- Create table
create table PRESCRIPTION_WORKFLOW
(
  ID_LANGUAGE    NUMBER(6) not null,
  ID_SOFTWARE    NUMBER(24) not null,
  ID_INSTITUTION NUMBER(24) not null,
  PROF_CAT_TYPE  VARCHAR2(1),
  TABELA_1       VARCHAR2(100) not null,
  FLG_1          VARCHAR2(100) not null,
  VALUE_1        VARCHAR2(50) not null,
  TABELA_2       VARCHAR2(100),
  FLG_2          VARCHAR2(100),
  VALUE_2        VARCHAR2(50),
  TABELA_3       VARCHAR2(100),
  FLG_3          VARCHAR2(100),
  VALUE_3        VARCHAR2(4),
  ICON           VARCHAR2(200),
  RANK           NUMBER(4),
  DESCRIÇÃO      VARCHAR2(200),
  FLG_AVAILABLE  VARCHAR2(1) not null
)
  ;
-- Add comments to the columns 
comment on column PRESCRIPTION_WORKFLOW.ID_LANGUAGE
  is 'Id da linguagem';
comment on column PRESCRIPTION_WORKFLOW.ID_SOFTWARE
  is 'Id do software ( 0 é válidao para todos)';
comment on column PRESCRIPTION_WORKFLOW.ID_INSTITUTION
  is 'Id da instituição ( 0 é válido para todas)';
comment on column PRESCRIPTION_WORKFLOW.PROF_CAT_TYPE
  is 'Categoria profissional  ( Nullo é válido para todas)';
comment on column PRESCRIPTION_WORKFLOW.TABELA_1
  is 'Tabela para comparar flag de workflow ';
comment on column PRESCRIPTION_WORKFLOW.FLG_1
  is 'Flag para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.VALUE_1
  is 'Valor para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.TABELA_2
  is 'Tabela para comparar flag de workflow ';
comment on column PRESCRIPTION_WORKFLOW.FLG_2
  is 'Flag para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.VALUE_2
  is 'Valor para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.TABELA_3
  is 'Tabela para comparar flag de workflow ';
comment on column PRESCRIPTION_WORKFLOW.FLG_3
  is 'Flag para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.VALUE_3
  is 'Valor para comparar workflow';
comment on column PRESCRIPTION_WORKFLOW.ICON
  is 'Icon usado no workflow';
comment on column PRESCRIPTION_WORKFLOW.RANK
  is 'Ranking';
comment on column PRESCRIPTION_WORKFLOW.DESCRIÇÃO
  is 'Descrição do linha ';
-- Create/Recreate indexes 


alter table  PRESCRIPTION_WORKFLOW  
rename column descrição to  descricao;
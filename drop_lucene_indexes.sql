-- drop indexes antigos
begin
pk_lucene_index_admin.drop_indexes('ALERT_CORE_DATA', 'CORE_TRANSLATION');
end;
/

begin
pk_lucene_index_admin.drop_indexes('ALERT', 'TRANSLATION');
end;
/


begin
  pk_lucene_index_admin.drop_indexes(i_table_owner => 'ALERT_CORE_DATA', i_table_name   => 'TRANSLATION' );
end;
/

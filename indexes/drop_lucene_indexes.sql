-- drop indexes antigos
begin
pk_lucene_index_admin.drop_indexes('ALERT_CORE_DATA', 'CORE_TRANSLATION');
end;
/

begin
pk_lucene_index_admin.drop_indexes('ALERT', 'TRANSLATION');
end;
/


begin
  execute immediate 'DROP TRIGGER A_IUD_055269_GLB_SRCH'; 
exception
  WHEN OTHERS THEN
    NULL;
end;
/

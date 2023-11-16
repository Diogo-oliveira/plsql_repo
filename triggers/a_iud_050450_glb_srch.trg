begin
  execute immediate 'DROP TRIGGER A_IUD_050450_GLB_SRCH; '; 
exception
  WHEN OTHERS THEN
    NULL;
end;
/

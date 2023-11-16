
CREATE OR REPLACE VIEW V_ACC_IDS AS
SELECT (SELECT MAX(id_sys_button) + 1
          FROM sys_button) id_sys_button,
       nvl((SELECT MAX(id_sys_button_prop) + 1
             FROM sys_button_prop
            WHERE id_sys_button_prop < 157307),
           (SELECT MAX(id_sys_button_prop) + 1
              FROM sys_button_prop)) id_sys_button_prop,
       (SELECT MAX(id_profile_templ_access) + 1
          FROM profile_templ_access) id_profile_templ_access,
       (SELECT MAX(id_sys_shortcut) + 1
          FROM sys_shortcut) id_sys_shortcut,
       (SELECT MAX(id_shortcut_pk) + 1
          FROM sys_shortcut) id_shortcut_pk
  FROM dual;

create or replace view MI_MED_REGULATION_PT as 
select distinct d.id_drug,dd.diploma_id as regulation_id,pdl.compart, dd.descr as regulation_descr,'PT' vers  
              FROM drug               d,
                   drug_emb           de,
                   drug_patol_esp_lnk pel,
                   drug_patol_dip_lnk pdl,
                   drug_diploma       dd,
                   drug_patol_esp     dpe
             WHERE  d.chnm_id = de.chnm_id
               AND pel.emb_id = de.emb_id
               AND pdl.patol_dip_lnk_id = pel.patol_dip_lnk_id
               AND dd.diploma_id = pdl.diploma_id
               AND dpe.patol_esp_id = pdl.patol_esp_id;
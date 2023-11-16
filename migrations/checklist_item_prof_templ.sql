-- CHANGED BY: Teresa Coutinho
-- CHANGE DATE: 03/12/2014 09:11
-- CHANGE REASON: [ALERT-262353] Migration of profiles in the checklists definitions in accordance with the New Simplified Profile.
-- Disables FK constraint to allow change values
ALTER TABLE CHECKLIST_ITEM_PROF_TEMPL DISABLE CONSTRAINT CHKIP_CHKP_FK;

-- Migrate profiles in checklist content
DECLARE
    l_id_profile_template profile_template.id_profile_template%TYPE;
    
    l_profiles    table_number := table_number(33, 34, 38, 39, 40, 44, 64, 71, 72, 75, 89, 90, 91,
                                               92, 93, 94, 95, 97, 98, 140, 141, 142, 143,
                                               144, 145, 146, 147, 150, 151, 153, 154, 155, 156,
                                               400, 401, 408, 409, 410, 412, 413, 420, 421, 430,
                                               431, 432, 433, 440, 441, 460, 461, 470, 471, 472,
                                               473, 476, 477, 481, 482, 484, 485, 486, 487, 600,
                                               601, 602, 603, 605, 606, 607, 608, 610, 611, 612,
                                               617, 640, 641, 642, 643, 655, 665, 670, 671, 672,
                                               676, 678, 679, 688, 689, 691, 692, 695, 696, 811,
                                               812, 813, 814, 815, 816, 817, 818, 820, 828, 829,
                                               830, 834, 851, 852, 920, 921, 922, 926, 927, 928,
                                               932, 933, 934, 935, 938, 939, 940, 944, 945, 950,
                                               615, 618, 645, 673, 683, 685, 687, 850, 853);                                              
    
BEGIN
    -- Migration of authorized profiles for checklist item (CHECKLIST_ITEM_PROF_TEMPL)
    FOR rec IN (SELECT *
                  FROM checklist_item_prof_templ chkip
                  JOIN TABLE(l_profiles) p
                    ON p.column_value = chkip.id_profile_template)
    LOOP
        l_id_profile_template := NULL;
    
        IF (rec.id_profile_template IN (400, 420, 430, 440, 460, 476, 477, 482))
        THEN
            l_id_profile_template := 483; -- EDIS Specialist Physician
        ELSIF (rec.id_profile_template IN (432))
        THEN
            l_id_profile_template := 488; -- EDIS Resident Physician
        ELSIF (rec.id_profile_template IN (412, 433, 484))
        THEN
            l_id_profile_template := 490; -- EDIS Student Physician        
        ELSIF (rec.id_profile_template IN (410, 413, 421, 470, 481))
        THEN
            l_id_profile_template := 492; -- EDIS Nurse Practitioner
        ELSIF (rec.id_profile_template IN (401, 409, 431, 441, 461, 471, 472, 485))
        THEN
            l_id_profile_template := 493; -- EDIS Registered Nurse
        ELSIF (rec.id_profile_template IN (473, 487))
        THEN
            l_id_profile_template := 494; -- EDIS Student Nurse
        ELSIF (rec.id_profile_template IN (408, 486))
        THEN
            l_id_profile_template := 496; -- EDIS Certified Nursing Assistant
        
        ELSIF (rec.id_profile_template IN (610, 611, 612, 615, 617, 618, 673, 672, 811, 812))
        THEN
            l_id_profile_template := 613; -- INP Registered Nurse
        ELSIF (rec.id_profile_template IN (813, 683))
        THEN
            l_id_profile_template := 682; -- INP Student Nurse
        ELSIF (rec.id_profile_template IN (685))
        THEN
            l_id_profile_template := 684; -- INP Licensed Practical Nurse (LPN)
        ELSIF (rec.id_profile_template IN (687, 814, 815, 820))
        THEN
            l_id_profile_template := 686; -- INP Certified Nursing Assistant
        ELSIF (rec.id_profile_template IN (640, 641, 642, 643, 645, 665, 676, 834))
        THEN
            l_id_profile_template := 810; -- INP Nurse Practitioner
        ELSIF (rec.id_profile_template IN (691, 695))
        THEN
            l_id_profile_template := 854; -- INP Resident Physician
        ELSIF (rec.id_profile_template IN (688, 689, 692, 696, 818, 830))
        THEN
            l_id_profile_template := 855; -- INP Student Physician
        ELSIF (rec.id_profile_template IN (678, 679))
        THEN
            l_id_profile_template := 856; -- INP Physician Assistant
        
        ELSIF (rec.id_profile_template IN
              (600, 601, 602, 603, 605, 606, 607, 608, 655, 670, 671, 816, 817, 828, 829, 850, 851, 852, 853))
        THEN
            l_id_profile_template := 857; -- INP Specialist Physician
        ELSIF (rec.id_profile_template IN (33, 38, 44, 71, 75, 89, 90, 93, 95, 98, 151, 154, 926, 927, 938, 939, 950))
        THEN
            l_id_profile_template := 951; -- OUTP Specialist Physician
        ELSIF (rec.id_profile_template IN (144, 145))
        THEN
            l_id_profile_template := 952; -- OUTP Resident Physician
        ELSIF (rec.id_profile_template IN (146, 147, 928, 940))
        THEN
            l_id_profile_template := 953; -- OUTP - Student Physician
        ELSIF (rec.id_profile_template IN (40, 64, 143, 155, 156, 920, 932, 944, 945))
        THEN
            l_id_profile_template := 956; -- OUTP Nurse Practitioner
        ELSIF (rec.id_profile_template IN (34, 39, 72, 91, 92, 97, 140, 150, 153, 921, 922, 933, 934))
        THEN
            l_id_profile_template := 957; -- OUTP Registered Nurse
        ELSIF (rec.id_profile_template IN (141))
        THEN
            l_id_profile_template := 958; -- OUTP Licensed Practical Nurse (LPN)
        ELSIF (rec.id_profile_template IN (142))
        THEN
            l_id_profile_template := 959; -- OUTP Certified Nursing Assistant (CNA)
        ELSIF (rec.id_profile_template IN (935))
        THEN
            l_id_profile_template := 960; -- OUTP Student Nurse 
        END IF;
    
        -- Verifies that the new profile exists
        BEGIN
            SELECT pt.id_profile_template
              INTO l_id_profile_template
              FROM profile_template pt
             WHERE pt.id_profile_template = l_id_profile_template;
        
        EXCEPTION
            WHEN no_data_found THEN
                -- The new profile does not exist in this DB yet, so the migration to this profile is ignored
                l_id_profile_template := NULL;
        END;
    
        IF l_id_profile_template IS NOT NULL
        THEN
            -- Migrate profile of checklist item to the new one
            BEGIN
                UPDATE checklist_item_prof_templ chkip
                   SET chkip.id_profile_template = l_id_profile_template
                 WHERE chkip.flg_content_creator = rec.flg_content_creator
                   AND chkip.internal_name = rec.internal_name
                   AND chkip.version = rec.version
                   AND chkip.item = rec.item
                   AND chkip.id_profile_template = rec.id_profile_template;
            EXCEPTION
                WHEN dup_val_on_index THEN
                    -- This profile is already defined for this item
                    DELETE FROM checklist_item_prof_templ chkip
                     WHERE chkip.flg_content_creator = rec.flg_content_creator
                       AND chkip.internal_name = rec.internal_name
                       AND chkip.version = rec.version
                       AND chkip.item = rec.item
                       AND chkip.id_profile_template = rec.id_profile_template;
            END;
        END IF;
    END LOOP;

    l_id_profile_template := NULL;

    --Migration of authorized profiles for checklist (CHECKLIST_PROF_TEMPL)
    FOR rec IN (SELECT *
                  FROM checklist_prof_templ chkp
                  JOIN TABLE(l_profiles) p
                    ON p.column_value = chkp.id_profile_template)
    LOOP
        l_id_profile_template := NULL;
    
        IF (rec.id_profile_template IN (400, 420, 430, 440, 460, 476, 477, 482))
        THEN
            l_id_profile_template := 483; -- EDIS Specialist Physician
        ELSIF (rec.id_profile_template IN (432))
        THEN
            l_id_profile_template := 488; -- EDIS Resident Physician
        ELSIF (rec.id_profile_template IN (412, 433, 484))
        THEN
            l_id_profile_template := 490; -- EDIS Student Physician        
        ELSIF (rec.id_profile_template IN (410, 413, 421, 470, 481))
        THEN
            l_id_profile_template := 492; -- EDIS Nurse Practitioner
        ELSIF (rec.id_profile_template IN (401, 409, 431, 441, 461, 471, 472, 485))
        THEN
            l_id_profile_template := 493; -- EDIS Registered Nurse
        ELSIF (rec.id_profile_template IN (473, 487))
        THEN
            l_id_profile_template := 494; -- EDIS Student Nurse
        ELSIF (rec.id_profile_template IN (408, 486))
        THEN
            l_id_profile_template := 496; -- EDIS Certified Nursing Assistant
        
        ELSIF (rec.id_profile_template IN (610, 611, 612, 615, 617, 618, 673, 672, 811, 812))
        THEN
            l_id_profile_template := 613; -- INP Registered Nurse
        ELSIF (rec.id_profile_template IN (813, 683))
        THEN
            l_id_profile_template := 682; -- INP Student Nurse
        ELSIF (rec.id_profile_template IN (685))
        THEN
            l_id_profile_template := 684; -- INP Licensed Practical Nurse (LPN)
        ELSIF (rec.id_profile_template IN (687, 814, 815, 820))
        THEN
            l_id_profile_template := 686; -- INP Certified Nursing Assistant
        ELSIF (rec.id_profile_template IN (640, 641, 642, 643, 645, 665, 676, 834))
        THEN
            l_id_profile_template := 810; -- INP Nurse Practitioner
        ELSIF (rec.id_profile_template IN (691, 695))
        THEN
            l_id_profile_template := 854; -- INP Resident Physician
        ELSIF (rec.id_profile_template IN (688, 689, 692, 696, 818, 830))
        THEN
            l_id_profile_template := 855; -- INP Student Physician
        ELSIF (rec.id_profile_template IN (678, 679))
        THEN
            l_id_profile_template := 856; -- INP Physician Assistant
        
        ELSIF (rec.id_profile_template IN
              (600, 601, 602, 603, 605, 606, 607, 608, 655, 670, 671, 816, 817, 828, 829, 850, 851, 852, 853))
        THEN
            l_id_profile_template := 857; -- INP Specialist Physician
        ELSIF (rec.id_profile_template IN (33, 38, 44, 71, 75, 89, 90, 93, 95, 98, 151, 154, 926, 927, 938, 939, 950))
        THEN
            l_id_profile_template := 951; -- OUTP Specialist Physician
        ELSIF (rec.id_profile_template IN (144, 145))
        THEN
            l_id_profile_template := 952; -- OUTP Resident Physician
        ELSIF (rec.id_profile_template IN (146, 147, 928, 940))
        THEN
            l_id_profile_template := 953; -- OUTP - Student Physician
        ELSIF (rec.id_profile_template IN (40, 64, 143, 155, 156, 920, 932, 944, 945))
        THEN
            l_id_profile_template := 956; -- OUTP Nurse Practitioner
        ELSIF (rec.id_profile_template IN (34, 39, 72, 91, 92, 97, 140, 150, 153, 921, 922, 933, 934))
        THEN
            l_id_profile_template := 957; -- OUTP Registered Nurse
        ELSIF (rec.id_profile_template IN (141))
        THEN
            l_id_profile_template := 958; -- OUTP Licensed Practical Nurse (LPN)
        ELSIF (rec.id_profile_template IN (142))
        THEN
            l_id_profile_template := 959; -- OUTP Certified Nursing Assistant (CNA)
        ELSIF (rec.id_profile_template IN (935))
        THEN
            l_id_profile_template := 960; -- OUTP Student Nurse 
        END IF;
    
        -- Checks if the new profile exists
        BEGIN
            SELECT pt.id_profile_template
              INTO l_id_profile_template
              FROM profile_template pt
             WHERE pt.id_profile_template = l_id_profile_template;
        
        EXCEPTION
            WHEN no_data_found THEN
                -- The new profile does not exist in this DB yet, so the migration to this profile is ignored
                l_id_profile_template := NULL;
        END;
    
        IF l_id_profile_template IS NOT NULL
        THEN
            -- Migrate profile of checklist to the new one
            BEGIN
                UPDATE checklist_prof_templ chkp
                   SET chkp.id_profile_template = l_id_profile_template
                 WHERE chkp.flg_content_creator = rec.flg_content_creator
                   AND chkp.internal_name = rec.internal_name
                   AND chkp.version = rec.version
                   AND chkp.id_profile_template = rec.id_profile_template;
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                    -- This profile is already defined for this checklist
                    DELETE checklist_prof_templ chkp
                     WHERE chkp.flg_content_creator = rec.flg_content_creator
                       AND chkp.internal_name = rec.internal_name
                       AND chkp.version = rec.version
                       AND chkp.id_profile_template = rec.id_profile_template;
            END;
        END IF;
    END LOOP;
END;
/
-- Re-enable FK constraint 
ALTER TABLE CHECKLIST_ITEM_PROF_TEMPL ENABLE CONSTRAINT CHKIP_CHKP_FK;
-- CHANGE END: Teresa Coutinho
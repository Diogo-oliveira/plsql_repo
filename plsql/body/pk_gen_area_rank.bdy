/*-- Last Change Revision: $Rev: 2027169 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:21 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_gen_area_rank IS

    FUNCTION get_rank
    (
        i_institution IN gen_area_rank.id_institution%TYPE,
        i_area        IN gen_area_rank.area%TYPE,
        i_values      IN table_varchar,
        o_rank_value  OUT gen_area_rank.rank_value%TYPE,
        o_rank_order  OUT gen_area_rank.rank_order%TYPE
    ) RETURN BOOLEAN IS
    
        /*
        * Public Function. Obtain the rank classification for a specifica record.   
        *
        *
        * @param    i_institution      Institution
        * @param    i_area             Area that is using this function
        * @param    i_values           Arrays of values for the bind variables of the string criteria
        * @param    o_rank_value       Rank classification for the specific recor
        * @param    o_rank_order       Rank order for the same classification
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     JRS
        * @version    0.1
        * @since      2008/11/04
        */
    
        l_query   gen_area_rank_criteria.criteria%TYPE;
        l_id_rank gen_area_rank.id_rank%TYPE;
    
        invalid_parameters EXCEPTION;
        double_classification EXCEPTION;
        no_classification EXCEPTION;
        no_rank EXCEPTION;
    BEGIN
    
        IF i_values.COUNT = 0
        THEN
            RAISE invalid_parameters;
        END IF;
    
        --single query with all the criteria an bind variables
        BEGIN
            SELECT criteria
              INTO l_query
              FROM gen_area_rank_criteria
             WHERE area = i_area;
        
            BEGIN
            
                EXECUTE IMMEDIATE l_query
                    USING OUT l_id_rank, IN i_values(1), IN i_values(2), IN i_values(3), IN i_values(4), IN i_values(5), IN i_values(6), IN i_values(7), IN i_values(8), IN i_values(9), IN i_values(10);
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                    RAISE double_classification;
                WHEN no_data_found THEN
                    RAISE no_classification;
            END;
        
            SELECT rank_value, rank_order
              INTO o_rank_value, o_rank_order
              FROM gen_area_rank
             WHERE id_rank = l_id_rank
               AND area = i_area
               AND id_institution = (SELECT decode(COUNT(1), 0, 0, i_institution)
                                       FROM gen_area_rank gar1
                                      WHERE gar1.id_institution = i_institution
                                        AND gar1.area = i_area);
        
        EXCEPTION
            WHEN no_data_found THEN
                RAISE no_rank;
        END;
    
        IF o_rank_value IS NULL
           OR o_rank_order IS NULL
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN invalid_parameters THEN
            pk_alertlog.log_error('Invalid parameters for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN double_classification THEN
            pk_alertlog.log_error('Double classification for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN no_classification THEN
            pk_alertlog.log_error('No classification for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN no_rank THEN
            pk_alertlog.log_error('No rank for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution || ' area-' ||
                                  i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_fatal('Others for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution || ' area-' ||
                                  i_area || ' date-' || current_timestamp || '-' || SQLERRM);
            RETURN FALSE;
    END get_rank;
		
		FUNCTION get_rank
    (
        i_institution             IN gen_area_rank.id_institution%TYPE,
        i_area                    IN gen_area_rank.area%TYPE,
        i_values_varch            IN table_varchar,
				i_values_numb             IN table_number,
				i_values_tstz             IN table_timestamp_tz,
		    o_rank_value  OUT gen_area_rank.rank_value%TYPE,
        o_rank_order  OUT gen_area_rank.rank_order%TYPE
    ) RETURN BOOLEAN IS
    
        /*
        * Public Function. Obtain the rank classification for a specifica record.   
        *
        *
        * @param    i_institution      Institution
        * @param    i_area             Area that is using this function
        * @param    i_values_varch     Arrays of values of type varchar for the bind variables of the string criteria
        * @param    i_values_numb      Arrays of values of type number for the bind variables of the string criteria
        * @param    i_values_tstz      Arrays of values of type timestamp_tz for the bind variables of the string criteria
        * @param    o_rank_value       Rank classification for the specific recor
        * @param    o_rank_order       Rank order for the same classification
        *
        * @return     boolean type, "False" on error or "True" if success
        * @author     JRS
        * @version    0.1
        * @since      2008/11/04
        */
    
        l_query   gen_area_rank_criteria.criteria%TYPE;
        l_id_rank gen_area_rank.id_rank%TYPE;
    
        invalid_parameters EXCEPTION;
        double_classification EXCEPTION;
        no_classification EXCEPTION;
        no_rank EXCEPTION;
    BEGIN
    
        IF i_values_varch.COUNT = 0 OR i_values_numb.COUNT = 0 OR i_values_tstz.COUNT = 0
        THEN
            RAISE invalid_parameters;
        END IF;
    
        --single query with all the criteria an bind variables
        BEGIN
            IF i_area = 'MEDICATION' THEN
                l_id_rank := PK_API_PFH_IN.GET_PRESC_RANK
                    (
                        i_lang       => NULL,
                        i_prof       => NULL,
                        i_id_presc   => i_values_numb(1)
                    );
            
            ELSE
            SELECT criteria
              INTO l_query
              FROM gen_area_rank_criteria
             WHERE area = i_area;
        
            BEGIN
            
                EXECUTE IMMEDIATE l_query
                    USING OUT l_id_rank, 
										      IN i_values_varch(1), 
													IN i_values_varch(2), 
													IN i_values_varch(3), 
													IN i_values_varch(4), 
													IN i_values_varch(5), 
													IN i_values_varch(6), 
													IN i_values_varch(7), 
													IN i_values_varch(8),
													IN i_values_numb(1), 
													IN i_values_numb(2), 
													IN i_values_numb(3), 
													IN i_values_numb(4), 
													IN i_values_numb(5), 
													IN i_values_numb(6), 
													IN i_values_numb(7), 
													IN i_values_numb(8), 
													IN i_values_tstz(1), 
													IN i_values_tstz(2),
													IN i_values_tstz(3), 
													IN i_values_tstz(4),
													IN i_values_tstz(5), 
													IN i_values_tstz(6),
													IN i_values_tstz(7), 
													IN i_values_tstz(8);
            
            EXCEPTION
                WHEN dup_val_on_index THEN
                    RAISE double_classification;
                WHEN no_data_found THEN
                    RAISE no_classification;
            END;
						END IF;
						
            SELECT rank_value, rank_order
              INTO o_rank_value, o_rank_order
              FROM gen_area_rank
             WHERE id_rank = l_id_rank
               AND area = i_area
               AND id_institution = (SELECT decode(COUNT(1), 0, 0, i_institution)
                                       FROM gen_area_rank gar1
                                      WHERE gar1.id_institution = i_institution
                                        AND gar1.area = i_area);
        
        EXCEPTION
            WHEN no_data_found THEN
								pk_alertlog.log_debug('No rank value for id_rank '||l_id_rank||' in PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
						
                RAISE no_rank;
        END;
    
        IF o_rank_value IS NULL
           OR o_rank_order IS NULL
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN invalid_parameters THEN
            pk_alertlog.log_error('Invalid parameters for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN double_classification THEN
            pk_alertlog.log_error('Double classification for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN no_classification THEN
            pk_alertlog.log_error('No classification for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution ||
                                  ' area-' || i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN no_rank THEN
            pk_alertlog.log_error('No rank for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution || ' area-' ||
                                  i_area || ' date-' || current_timestamp);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_fatal('Others for PK_GEN_AREA_RANK.GET_RANK: institution-' || i_institution || ' area-' ||
                                  i_area || ' date-' || current_timestamp || '-' || SQLERRM);
            RETURN FALSE;
    END get_rank;

    FUNCTION get_rank
    (
        i_institution  IN gen_area_rank.id_institution%TYPE,
        i_area         IN gen_area_rank.area%TYPE,
        i_values_varch IN table_varchar,
        i_values_numb  IN table_number,
        i_values_tstz  IN table_timestamp_tz
        
    ) RETURN rank_values_type IS
    
        l_rank_value gen_area_rank.rank_value%TYPE;
        l_rank_order gen_area_rank.rank_order%TYPE;
    
    BEGIN
    
        IF NOT pk_gen_area_rank.get_rank(i_institution  => i_institution,
                                         i_area         => i_area,
                                         i_values_varch => i_values_varch,
                                         i_values_numb  => i_values_numb,
                                         i_values_tstz  => i_values_tstz,
                                         o_rank_value   => l_rank_value,
                                         o_rank_order   => l_rank_order)
        THEN
            raise g_exception;    
        END IF;
        RETURN rank_values_type(l_rank_value, l_rank_order);
    
    EXCEPTION
        WHEN OTHERS THEN
            raise g_exception;       
    END get_rank;

BEGIN
    -- Log initialization.
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_gen_area_rank;
/

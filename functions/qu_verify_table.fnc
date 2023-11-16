CREATE OR REPLACE FUNCTION qu_verify_TABLE (
   delimiter_in IN VARCHAR2 DEFAULT ','
   )
   RETURN VARCHAR2 AUTHID CURRENT_USER
IS
   TYPE name_t IS TABLE OF user_objects.object_name%TYPE
      INDEX BY BINARY_INTEGER;

   TYPE status_t IS TABLE OF user_objects.status%TYPE
      INDEX BY BINARY_INTEGER;

   l_names            name_t;
   l_stati            status_t;
   l_first            PLS_INTEGER;
   l_bad_row          PLS_INTEGER;
   l_bad_name         user_objects.object_name%TYPE;
   object_not_found   EXCEPTION;

   l_have_utplsql BOOLEAN;

   retval VARCHAR2(32767);

   FUNCTION is_utplsql_installed RETURN BOOLEAN
   IS
      l_version VARCHAR2(32767);
   BEGIN
      EXECUTE IMMEDIATE 'SELECT utPLSQL.VERSION from DUAL'
                   INTO l_version;

      RETURN l_version IS NOT NULL;
   EXCEPTION
      WHEN OTHERS
      THEN
         RETURN FALSE;
   END is_utplsql_installed;

   PROCEDURE add_invalid_object (NAME_IN IN VARCHAR2) IS
   BEGIN
      retval := retval || delimiter_in || name_in || ' (TABLE) is not valid';
   EXCEPTION
      -- If I butt up against the 32K limit, just keep adding
      -- whatever you can from the next object...
      WHEN VALUE_ERROR THEN NULL;
   END add_invalid_object;

   PROCEDURE add_object_not_found (NAME_IN IN VARCHAR2) IS
   BEGIN
      retval := retval || delimiter_in || name_in || ' (TABLE) is not installed';
   EXCEPTION
      -- If I butt up against the 32K limit, just keep adding
      -- whatever you can from the next object...
      WHEN VALUE_ERROR THEN NULL;
   END add_object_not_found;

   PROCEDURE add_errors (NAME_IN IN VARCHAR2)
   IS
      TYPE error_info_t IS TABLE OF VARCHAR2 (2000)
         INDEX BY BINARY_INTEGER;

      l_errors   error_info_t;
      l_row      PLS_INTEGER;
   BEGIN
      SELECT 'Line ' || line || ' Position: ' || POSITION || ' Text: ' || text
        bulk collect INTO l_errors
        FROM user_errors
       WHERE NAME = NAME_IN AND TYPE = 'TABLE';

      l_row := l_errors.FIRST;

      WHILE (l_row IS NOT NULL)
      LOOP
         retval := retval || delimiter_in || l_errors (l_row);
         l_row := l_errors.NEXT (l_row);
      END LOOP;
   EXCEPTION
      -- If I butt up against the 32K limit, just keep adding
      -- whatever you can from the next object...
      WHEN VALUE_ERROR THEN NULL;
   END add_errors;

   PROCEDURE check_object (first_in IN PLS_INTEGER, NAME_IN IN VARCHAR2)
   IS
      l_row          PLS_INTEGER := first_in;
      valid_object   EXCEPTION;
      invalid_object   EXCEPTION;
   BEGIN
--      IF NOT l_have_utPLSQL AND name_in LIKE 'QU%'
--      THEN
--         -- Skip this, since we don't need QU elements.
--         NULL;
--      ELSE
      l_bad_name := NAME_IN;

      WHILE (l_row IS NOT NULL)
      LOOP
         IF l_names (l_row) = NAME_IN
         THEN
            IF l_stati (l_row) = 'INVALID'
            THEN
               l_bad_row := l_row;
               add_invalid_object (name_in);
               add_errors (name_in);
               RAISE invalid_object;
            ELSIF l_stati (l_row) = 'VALID'
            THEN
               RAISE valid_object;
            END IF;
         ELSE
            l_row := l_names.NEXT (l_row);
         END IF;
      END LOOP;

      add_object_not_found (name_in);
--      END IF;
   EXCEPTION
      WHEN valid_object OR invalid_object
      THEN
         NULL;
   END check_object;

BEGIN
   l_have_utplsql := is_utplsql_installed;

   SELECT object_name, status
   BULK COLLECT INTO l_names, l_stati
     FROM user_objects
    WHERE object_type = 'TABLE';

   l_first := l_names.FIRST;
   check_object (l_first, 'QU_ALL_ARGUMENTS');
   check_object (l_first, 'QU_ASSERTION');
   check_object (l_first, 'QU_ASSERTION_CODE');
   check_object (l_first, 'QU_ASSERTION_GROUP');
   check_object (l_first, 'QU_ASSERTION_HDR');
   check_object (l_first, 'QU_ASSERTION_PH');
   check_object (l_first, 'QU_ATTRIBUTES');
   check_object (l_first, 'QU_DATATYPE');
   check_object (l_first, 'QU_DEMO_CATEGORY');
   check_object (l_first, 'QU_DEMO_TOPIC');
   check_object (l_first, 'QU_ERROR');
   check_object (l_first, 'QU_ERR_CONTEXT');
   check_object (l_first, 'QU_ERR_INSTANCE');
   check_object (l_first, 'QU_HARNESS');
   check_object (l_first, 'QU_INPUT');
   check_object (l_first, 'QU_INTVAL');
   check_object (l_first, 'QU_INTVAL_HDR');
   check_object (l_first, 'QU_LOG');
   check_object (l_first, 'QU_OPERATOR');
   check_object (l_first, 'QU_OUTCOME');
   check_object (l_first, 'QU_PLACEHOLDER');
   check_object (l_first, 'QU_RESULT');
   check_object (l_first, 'QU_SUBSTITUTION');
   check_object (l_first, 'QU_SUITE');
   check_object (l_first, 'QU_SUITE_HARNESS');
   check_object (l_first, 'QU_TEMPLATE');
   check_object (l_first, 'QU_TEST_CASE');
   check_object (l_first, 'QU_TEST_ELEMENT');
   check_object (l_first, 'QU_TE_INTVAL');
   check_object (l_first, 'QU_UNIT_TEST');
   RETURN retval;
EXCEPTION
   WHEN OTHERS
   THEN
      RETURN 'Unknown error occurred';
END qu_verify_TABLE;
/

CREATE OR REPLACE TYPE aggr_string_concat AS OBJECT (
   ps_string_so_far   VARCHAR2 (32767),

   STATIC FUNCTION odciaggregateinitialize (po_sctx IN OUT aggr_string_concat)
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregateiterate (
      self   IN OUT   aggr_string_concat,
      val    IN       VARCHAR2
   )
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregateterminate (
      self          IN       aggr_string_concat,
      ps_returnvalue   OUT      VARCHAR2,
      pn_flags         IN       NUMBER
   )
      RETURN NUMBER,
   MEMBER FUNCTION odciaggregatemerge (
      self   IN OUT   aggr_string_concat,
      po_ctx2   IN       aggr_string_concat
   )
      RETURN NUMBER
);
/

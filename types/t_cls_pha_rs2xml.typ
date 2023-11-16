
set scan off;

create or replace type t_cls_pha_rs2xml as object (

	/*
	 * @author		Rui Marante
	 * @since		2011-01-19
	 * @version		ZANOB 0.1
	 * @notes		object type for rs <-> xml management and transfer over db-links
	*/


	--PUBLIC PROPERTIES
		class_name				varchar2(30 char),
		--
		tbl_name				varchar2(100 char),
		col_names				table_varchar,
		col_data_types			table_varchar,
		col_count				number,
		row_count				number,
		--
		xtra_info				varchar2(200 char),
		--
		active_col_idx			number,
		active_row_xpath		varchar2(4000 char),
		--
		xml_data				xmltype,
		cur_sql_query			varchar2(32000 char),
		--
		do_log					varchar2(1 char),
		--

		--data types "constants"
		C_DT_NUMBER				varchar2(50 char),
		C_DT_VARCHAR2			varchar2(50 char),
		C_DT_TSTZ				varchar2(50 char),
		C_DT_VARCHAR2_COLL		varchar2(50 char),
		C_DT_NUMBER_COLL		varchar2(50 char),
		C_DT_NUMBER_MATRIX		varchar2(50 char),
		C_DT_VARCHAR2_MATRIX	varchar2(50 char),
		C_DT_PROFESSIONAL		varchar2(50 char),
		C_DT_OTHER				varchar2(50 char),

	--CONSTRUCTOR
		constructor function t_cls_pha_rs2xml
		(
			i_tbl_name in varchar2
		)
		return self as result,


	--METHODS
		member procedure setXInfo
		(
			i_info	in	varchar2
		),

		
		member procedure addCol
		(
			i_col_name		in varchar2, 
			i_col_data_type	in varchar2
		),

		
		member procedure processHeader,

		
		member procedure addRow,

		
		member function getColNum
		(
			i_num in number
		)
		return number,

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in varchar2
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in number
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_varchar
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_number
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2, 
			i_col_value	in varchar2
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2, 
			i_col_value	in number
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_varchar
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_number
		),

		
		member procedure addColValue

		(
			i_col_num	in number default null,
			i_col_value	in timestamp with local time zone
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in timestamp with local time zone
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_table_number
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_table_number
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_table_varchar
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_table_varchar
		),

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in t_rec_pha_prof
		),

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in t_rec_pha_prof
		),

		
		member function toXML
		return xmltype,

		
		member function toString
		return varchar2,

		
		member function toCLob
		return clob,

		
		member function submit2table
		return number,


	--STATIC METHODS BEGIN
		static function submit2table
		(
			i_xml_data		in	xmltype,
			i_xtra_info		in	varchar2 default null,
			i_db_link_name	in	varchar2 default null
		)
		return number,

		
		static function stripSpecialChars
		(
			i_str	in varchar2
		)
		return varchar2,

		
		static function toVarchar2Collection
		(
			i_xml_collection	in	xmltype,
			i_xpath_to_elements	in	varchar2
		)
		return table_varchar,

		
		static function toNumberCollection
		(
			i_xml_collection	in	xmltype,
			i_xpath_to_elements	in	varchar2
		)
		return table_number,

		
		static function serializeTSTZ
		(
			i_date	in	timestamp with local time zone
		)
		return varchar,

		
		static function serializeTblVarchar
		(
			i_tbl_x	in table_varchar
		)
		return xmltype,

		
		static function serializeTblVarchar
		(
			i_tbl_s	in table_varchar
		)
		return varchar2,

		
		static function serializeTblTblVarchar
		(
			i_tbl_tbl_x	in table_table_varchar
		)
		return xmltype,

		
		static function serializeTblTblVarchar
		(
			i_tbl_tbl_s	in table_table_varchar
		)
		return varchar2,

		
		static function serializeTblNumber
		(
			i_tbl_x	in table_number
		)
		return xmltype,

		
		static function serializeTblNumber
		(
			i_tbl_s	in table_number
		)
		return varchar2,

		
		static function serializeTblTblNumber
		(
			i_tbl_tbl_x	in table_table_number
		)
		return xmltype,

		
		static function serializeTblTblNumber
		(
			i_tbl_tbl_s	in table_table_number
		)
		return varchar2,

		
		static function serializeProfessional
		(
			i_prof_x	in	t_rec_pha_prof
		)
		return xmltype,

		
		static function serializeProfessional
		(
			i_prof_s	in	t_rec_pha_prof
		)
		return varchar2,


		--UNSERIALIZE!

		
		static function unSerializeTSTZ
		(
			i_dt_str	in	varchar2
		)
		return timestamp with local time zone,

		
		static function unSerializeTblVarchar
		(
			i_xml_tbl	in xmltype
		)
		return table_varchar,

		
		static function unSerializeTblVarchar
		(
			i_xml_tbl	in varchar2
		)
		return table_varchar,

		
		static function unSerializeTblNumber
		(
			i_xml_tbl	in xmltype
		)
		return table_number,

		
		static function unSerializeTblNumber
		(
			i_xml_tbl	in varchar2
		)
		return table_number,

		
		static function unSerializeTblTblNumber
		(
			i_xml_tbl	in	xmltype
		)
		return table_table_number,

		
		static function unSerializeTblTblVarchar
		(
			i_xml_tbl	in	xmltype
		)
		return table_table_varchar,

		
		static function unSerializeProfessional
		(
			i_xml_prof	in	xmltype
		)
		return t_rec_pha_prof,

		
		static function unSerializeProfessional
		(
			i_xml_prof	in	varchar2
		)
		return t_rec_pha_prof,
		--STATIC METHODS END

		
		member procedure resetCols,

		
		member procedure loadXML
		(
			i_xml	in	varchar2
		),

		
		member procedure loadXML
		(
			i_xml	in	clob
		),

		
		member procedure loadXML
		(
			i_id_xml		in	number,
			i_dblink_name	in	varchar2 default null
		),

		
		member procedure extractColsFromXML,

		
		member procedure genSQLExtractQuery,

		
		member procedure getCursor
		(
			o_cur out sys_refcursor
		)
);
/

create or replace type body t_cls_pha_rs2xml is

	/*
	 * @author		Rui Marante
	 * @since		2011-01-19
	 * @version		ZANOB 0.1
	 * @notes		object type for rs <-> xml management and transfer over db-links
	*/


	--CONSTRUCTOR
		constructor function t_cls_pha_rs2xml
		(
			i_tbl_name	in varchar2
		)
		return self as result
		is
		begin
			self.class_name				:= 'T_CLS_PHA_RS2XML';
			--
			self.xtra_info				:= null;
			self.tbl_name				:= i_tbl_name;
			self.col_names				:= table_varchar();
			self.col_data_types			:= table_varchar();
			self.col_count				:= 0;
			self.row_count				:= 0;
			self.xml_data				:= xmltype.createXML(xmlData => '<' || self.tbl_name || '/>');
			self.active_col_idx			:= 0;
			self.active_row_xpath		:= '';
			self.cur_sql_query			:= '';
			self.do_log					:= 'N'; --not in use. TBD: LOG!!

			--data types "constants"
			self.C_DT_NUMBER			:= 'NUMBER';
			self.C_DT_VARCHAR2			:= 'VARCHAR2';
			self.C_DT_TSTZ				:= 'TIMESTAMP WITH LOCAL TIME ZONE';
			self.C_DT_VARCHAR2_COLL		:= 'VARCHAR2_COLLECTION';
			self.C_DT_NUMBER_COLL		:= 'NUMBER_COLLECTION';
			self.C_DT_NUMBER_MATRIX		:= 'NUMBER_VAR_MATRIX';
			self.C_DT_VARCHAR2_MATRIX	:= 'VARCHAR2_VAR_MATRIX';
			self.C_DT_PROFESSIONAL		:= 'PROFESSIONAL';
			self.C_DT_OTHER				:= '???';

			return;
		end;

	--METHODS
		member procedure setXInfo
		(
			i_info	in	varchar2
		)
		is
		begin
			self.xtra_info := i_info;
		end setXInfo;

		
		member procedure addCol
		(
			i_col_name		in varchar2,
			i_col_data_type	in varchar2
		)
		is
		begin
			self.col_count := self.col_count + 1;
			self.col_names.extend(1);
			self.col_data_types.extend(1);
			self.col_names(self.col_count) := i_col_name;
			self.col_data_types(self.col_count) := i_col_data_type;
		end addCol;

		
		member procedure processHeader
		is
			l_xpath varchar2(400 char);
		begin
			l_xpath := '/' || self.tbl_name;
			self.xml_data := self.xml_data.appendChildXML(l_xpath, xmltype.createXML(xmlData => '<HEADER COLS="' || self.col_count || '"/>'));

			l_xpath := l_xpath || '/HEADER';
			for i in 1 .. self.col_count
			loop
				self.xml_data := self.xml_data.appendChildXML(l_xpath, xmltype.createXML(xmlData => '<COL NAME="' || self.col_names(i) || '" DATATYPE="' || self.col_data_types(i) || '"/>'));
			end loop;
		end processHeader;

		
		member procedure addRow
		is
			l_xpath varchar2(400 char);
		begin
			self.active_col_idx := 0;

			if (self.row_count = 0) then
				l_xpath := '/' || self.tbl_name;
				self.xml_data := self.xml_data.appendChildXML(l_xpath, xmltype.createXML(xmlData => '<ROWS COUNT=""/>')); --TBD update row count
			end if;

			l_xpath := '/' || self.tbl_name || '/ROWS';
			self.row_count := self.row_count + 1;
			self.xml_data := self.xml_data.appendChildXML(l_xpath, xmltype.createXML(xmlData => '<ROW ID="ROW' || self.row_count || '"/>'));
			self.active_row_xpath := l_xpath || '/ROW[@ID=''ROW' || self.row_count || ''']';

		end addRow;

		
		member function getColNum
		(
			i_num in number
		)
		return number
		is
			l_col_num	number := 0;
		begin
			if (i_num is not null) then
				l_col_num := i_num;
			else
				l_col_num := self.active_col_idx;
			end if;

			return l_col_num;
		end getColNum;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in varchar2
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in number
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_varchar
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_number
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in varchar2
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '>' || t_cls_pha_rs2xml.stripSpecialChars(i_col_value) || '</' || i_col_name || '>'));
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in number --TBD: serealize number to a specific format
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '>' || i_col_value || '</' || i_col_name || '>'));
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_varchar
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || ' COUNT="' || i_col_value.count || '"></' || i_col_name || '>'));
			for i in 1 .. i_col_value.count
			loop
				self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath || '/' || i_col_name, xmltype.createXML(xmlData => '<EL>' || t_cls_pha_rs2xml.stripSpecialChars(i_col_value(i)) || ' </EL>'));
			end loop;
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_number  --TBD: serealize number to a specific format
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || ' COUNT="' || i_col_value.count || '"></' || i_col_name || '>'));
			for i in 1 .. i_col_value.count
			loop
				self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath || '/' || i_col_name, xmltype.createXML(xmlData => '<EL>' || i_col_value(i) || ' </EL>'));
			end loop;
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in timestamp with local time zone
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in timestamp with local time zone
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '>' || t_cls_pha_rs2xml.serializeTSTZ(i_col_value) || '</' || i_col_name || '>'));
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_table_number
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_table_number
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '/>'));
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath || '/' || i_col_name, t_cls_pha_rs2xml.serializeTblTblNumber(i_tbl_tbl_x => i_col_value));
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in table_table_varchar
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in table_table_varchar
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '/>'));

			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath || '/' || i_col_name, t_cls_pha_rs2xml.serializeTblTblVarchar(i_tbl_tbl_x => i_col_value));
		end addColValue;

		
		member procedure addColValue
		(
			i_col_num	in number default null,
			i_col_value	in t_rec_pha_prof
		)
		is
		begin
			self.active_col_idx := self.active_col_idx + 1;
			self.addColValue(i_col_name => self.col_names(getColNum(i_num => i_col_num)), i_col_value => i_col_value);
		end addColValue;

		
		member procedure addColValue
		(
			i_col_name	in varchar2,
			i_col_value	in t_rec_pha_prof
		)
		is
		begin
			self.xml_data := self.xml_data.appendChildXML(self.active_row_xpath, xmltype.createXML(xmlData => '<' || i_col_name || '>' || t_cls_pha_rs2xml.serializeProfessional(i_prof_s => i_col_value) || '</' || i_col_name || '>'));
		end addColValue;
	--

		
		member function toXML
		return xmltype
		is
		begin
			return self.xml_data;
		end toXML;

		
		member function toString
		return varchar2
		is
		begin
			if (self.xml_data is not null) then
				return self.xml_data.getStringVal();
			else
				return null;
			end if;
		end toString;

		
		member function toCLob
		return clob
		is
		begin
			if (self.xml_data is not null) then
				return self.xml_data.getCLobVal();
			else
				return null;
			end if;
		end toCLob;

		
		member function submit2table
		return number
		is
			l_id_xml_row	number;
		begin
			execute immediate 
				'
				INSERT INTO pha_xml_data (id_xml_data, xml_data, xml_data_context_info) 
				VALUES (seq_pha_xml_data.nextval, :l_xml_data, :l_xml_data_context_info) 
				RETURNING id_xml_data INTO :l_id_xml_row
				'
			using
				in self.xml_data, in self.xtra_info, out l_id_xml_row;

			return l_id_xml_row;
		end submit2table;


		-- ************* XML -> RS
		--STATIC METHODS BEGIN
		static function submit2table
		(
			i_xml_data		in	xmltype,
			i_xtra_info		in	varchar2 default null,
			i_db_link_name	in	varchar2 default null
		)
		return number
		is
			l_id_xml_row	number;
		begin
			execute immediate 
				'
				INSERT INTO pha_xml_data' || i_db_link_name || ' (id_xml_data, xml_data, xml_data_context_info) 
				VALUES (seq_pha_xml_data.nextval, :l_xml_data, :l_xml_data_context_info) 
				RETURNING id_xml_data INTO :l_id_xml_row
				'
			using
				in i_xml_data, in i_xtra_info, out l_id_xml_row;

			return l_id_xml_row;
		end submit2table;

		
		static function stripSpecialChars
		(
			i_str	in varchar2
		)
		return varchar2
		is
			--TBD: Oracle has function for this? special chars .. XML encode ?
			l_str				varchar2(32000 char);
			l_special_chars		table_varchar;
			l_replace_char		table_varchar;
		begin
			l_str			:= i_str;
			l_special_chars	:= table_varchar('<', '>');
			l_replace_char	:= table_varchar('&lt;', '&gt;');

			for i in 1 .. l_special_chars.count
			loop
				l_str := replace(srcstr => l_str, oldsub => l_special_chars(i), newsub => l_replace_char(i));
			end loop;

			return l_str;
		end stripSpecialChars;

		
		static function toVarchar2Collection
		(
			i_xml_collection	in	xmltype,
			i_xpath_to_elements	in	varchar2
		)
		return table_varchar
		is
			l_tbl		table_varchar;
			l_el_count	number;
		begin
			l_tbl := table_varchar();
			l_el_count := i_xml_collection.extract(i_xpath_to_elements || '/@COUNT').getNumberVal();

			l_tbl.extend(l_el_count);
			for i in 1 .. l_el_count
			loop
				l_tbl(i) := rtrim(i_xml_collection.extract(i_xpath_to_elements || '/EL[' || i || ']/text()').getStringVal());
			end loop;

			return l_tbl;
		end toVarchar2Collection;

		
		static function toNumberCollection
		(
			i_xml_collection	in	xmltype,
			i_xpath_to_elements	in	varchar2
		)
		return table_number
		is
			l_tbl		table_number;
			l_el_count	number;
		begin
			l_tbl := table_number();
			l_el_count := i_xml_collection.extract(i_xpath_to_elements || '/@COUNT').getNumberVal();

			l_tbl.extend(l_el_count);
			for i in 1 .. l_el_count
			loop
				l_tbl(i) := to_number(i_xml_collection.extract(i_xpath_to_elements || '/EL[' || i || ']/text()').getStringVal());
			end loop;

			return l_tbl;
		end toNumberCollection;

	--
		
		static function serializeTSTZ
		(
			i_date	in	timestamp with local time zone
		)
		return varchar
		is
		begin
			if (i_date is null) then
				return null;
			else
				return to_char(i_date, 'YYYYMMDDHH24MISS TZD');
			end if;
		end serializeTSTZ;

		
		static function serializeTblVarchar
		(
			i_tbl_x	in table_varchar
		)
		return xmltype
		is
			l_xml_data	xmltype;
		begin
			l_xml_data := xmltype.createXML(xmlData => '<TABLE_VARCHAR COUNT="' || to_char(i_tbl_x.count) || '"/>');

			for i in 1 .. i_tbl_x.count
			loop
				--NOTE: with a space at the end (to avoid <EL/> in case of null elements) TBD! how to solver this??
				l_xml_data := l_xml_data.appendChildXML('/TABLE_VARCHAR', xmltype.createXML(xmlData => '<EL>' || t_cls_pha_rs2xml.stripSpecialChars(i_tbl_x(i)) || ' </EL>'));
			end loop;

			return l_xml_data;
		end serializeTblVarchar;

		
		static function serializeTblVarchar
		(
			i_tbl_s	in table_varchar
		)
		return varchar2
		is
		begin
			return t_cls_pha_rs2xml.serializeTblVarchar(i_tbl_x => i_tbl_s).getStringVal();
		end serializeTblVarchar;

		
		static function serializeTblTblVarchar
		(
			i_tbl_tbl_x	in table_table_varchar
		)
		return xmltype
		is
			l_xml_data	xmltype;
		begin
			l_xml_data := xmltype.createXML(xmlData => '<TABLE_TABLE_VARCHAR COUNT="' || to_char(i_tbl_tbl_x.count) || '"/>');

			for i in 1 .. i_tbl_tbl_x.count
			loop
				l_xml_data := l_xml_data.appendChildXML('/TABLE_TABLE_VARCHAR', t_cls_pha_rs2xml.serializeTblVarchar(i_tbl_x => i_tbl_tbl_x(i)));
			end loop;

			return l_xml_data;
		end serializeTblTblVarchar;


		static function serializeTblTblVarchar
		(
			i_tbl_tbl_s	in table_table_varchar
		)
		return varchar2
		is
		begin
			return t_cls_pha_rs2xml.serializeTblTblVarchar(i_tbl_tbl_x => i_tbl_tbl_s).getStringVal();
		end serializeTblTblVarchar;

		
		static function serializeTblNumber
		(
			i_tbl_x	in table_number
		)
		return xmltype
		is
			l_xml_data	xmltype;
		begin
			l_xml_data := xmltype.createXML(xmlData => '<TABLE_NUMBER COUNT="' || to_char(i_tbl_x.count) || '"/>');

			for i in 1 .. i_tbl_x.count
			loop
				--NOTE: with a space at the end (to avoid <EL/> in case of null elements) TBD! how to solver this??
				l_xml_data := l_xml_data.appendChildXML('/TABLE_NUMBER', xmltype.createXML(xmlData => '<EL>' || i_tbl_x(i) || ' </EL>'));
			end loop;

			return l_xml_data;
		end serializeTblNumber;

		
		static function serializeTblNumber
		(
			i_tbl_s	in table_number
		)
		return varchar2
		is
		begin
			return t_cls_pha_rs2xml.serializeTblNumber(i_tbl_x => i_tbl_s).getStringVal();
		end serializeTblNumber;

		
		static function serializeTblTblNumber
		(
			i_tbl_tbl_x	in table_table_number
		)
		return xmltype
		is
			l_xml_data	xmltype;
		begin
			l_xml_data := xmltype.createXML(xmlData => '<TABLE_TABLE_NUMBER COUNT="' || to_char(i_tbl_tbl_x.count) || '"/>');

			for i in 1 .. i_tbl_tbl_x.count
			loop
				l_xml_data := l_xml_data.appendChildXML('/TABLE_TABLE_NUMBER', t_cls_pha_rs2xml.serializeTblNumber(i_tbl_x => i_tbl_tbl_x(i)));
			end loop;

			return l_xml_data;
		end serializeTblTblNumber;

		
		static function serializeTblTblNumber
		(
			i_tbl_tbl_s	in table_table_number
		)
		return varchar2
		is
		begin
			return t_cls_pha_rs2xml.serializeTblTblNumber(i_tbl_tbl_x => i_tbl_tbl_s).getStringVal();
		end serializeTblTblNumber;

		
		static function serializeProfessional
		(
			i_prof_x	in	t_rec_pha_prof
		)
		return xmltype
		is
		begin
			return xmltype.createXML(xmlData => '<PROFESSIONAL ID="' || i_prof_x.id || '" INSTITUTION="' || i_prof_x.institution || '" SOFTWARE="' || i_prof_x.software || '"/>');
		end serializeProfessional;

		
		static function serializeProfessional
		(
			i_prof_s	in	t_rec_pha_prof
		)
		return varchar2
		is
		begin
			return t_cls_pha_rs2xml.serializeProfessional(i_prof_x => i_prof_s).getStringVal();
		end serializeProfessional;


		--UNSERIALIZE!
		
		static function unSerializeTSTZ
		(
			i_dt_str	in	varchar2
		)
		return timestamp with local time zone
		is
		begin
			if (i_dt_str is null) then
				return null;
			else
				return to_timestamp(i_dt_str, 'YYYYMMDDHH24MISS TZD');
			end if;
		end unSerializeTSTZ;

		
		static function unSerializeTblNumber
		(
			i_xml_tbl	in xmltype
		)
		return table_number
		is
		begin
			return t_cls_pha_rs2xml.toNumberCollection(i_xml_collection => i_xml_tbl, i_xpath_to_elements => '/TABLE_NUMBER');
		end unSerializeTblNumber;

		
		static function unSerializeTblVarchar
		(
			i_xml_tbl	in xmltype
		)
		return table_varchar
		is
		begin
			return t_cls_pha_rs2xml.toVarchar2Collection(i_xml_collection => i_xml_tbl, i_xpath_to_elements => '/TABLE_VARCHAR');
		end unSerializeTblVarchar;

		
		static function unSerializeTblVarchar
		(
			i_xml_tbl	in varchar2
		)
		return table_varchar
		is
		begin
			return t_cls_pha_rs2xml.toVarchar2Collection(i_xml_collection => xmltype.createXML(xmlData => i_xml_tbl), i_xpath_to_elements => '/TABLE_VARCHAR');
		end unSerializeTblVarchar;

		
		static function unSerializeTblNumber
		(
			i_xml_tbl	in varchar2
		)
		return table_number
		is
		begin
			return t_cls_pha_rs2xml.toNumberCollection(i_xml_collection => xmltype.createXML(xmlData => i_xml_tbl), i_xpath_to_elements => '/TABLE_NUMBER');
		end unSerializeTblNumber;

		
		static function unSerializeTblTblNumber
		(
			i_xml_tbl	in	xmltype
		)
		return table_table_number
		is
			l_tbl_tbl	table_table_number;
			l_el_count	number;
		begin
			l_tbl_tbl := table_table_number();
			l_el_count := i_xml_tbl.extract('//TABLE_TABLE_NUMBER/@COUNT').getNumberVal();

			l_tbl_tbl.extend(l_el_count);
			for i in 1 .. l_el_count
			loop
				l_tbl_tbl(i) := t_cls_pha_rs2xml.toNumberCollection(i_xml_collection => i_xml_tbl, i_xpath_to_elements => '//TABLE_TABLE_NUMBER/TABLE_NUMBER[' || i || ']');
			end loop;

			return l_tbl_tbl;
		end unSerializeTblTblNumber;

		
		static function unSerializeTblTblVarchar
		(
			i_xml_tbl	in	xmltype
		)
		return table_table_varchar
		is
			l_tbl_tbl	table_table_varchar;
			l_el_count	number;
		begin
			l_tbl_tbl := table_table_varchar();
			l_el_count := i_xml_tbl.extract('//TABLE_TABLE_VARCHAR/@COUNT').getNumberVal();

			l_tbl_tbl.extend(l_el_count);
			for i in 1 .. l_el_count
			loop
				l_tbl_tbl(i) := t_cls_pha_rs2xml.toVarchar2Collection(i_xml_collection => i_xml_tbl, i_xpath_to_elements => '//TABLE_TABLE_VARCHAR/TABLE_VARCHAR[' || i || ']');
			end loop;

			return l_tbl_tbl;
		end unSerializeTblTblVarchar;

		
		static function unSerializeProfessional
		(
			i_xml_prof	in	xmltype
		)
		return t_rec_pha_prof
		is
			l_id			number;
			l_institution	number;
			l_software		number;
		begin
			l_id			:= i_xml_prof.extract('//PROFESSIONAL/@ID').getNumberVal();
			l_institution	:= i_xml_prof.extract('//PROFESSIONAL/@INSTITUTION').getNumberVal();
			l_software		:= i_xml_prof.extract('//PROFESSIONAL/@SOFTWARE').getNumberVal();

			return t_rec_pha_prof(l_id, l_institution, l_software);
		end unSerializeProfessional;

		
		static function unSerializeProfessional
		(
			i_xml_prof	in	varchar2
		)
		return t_rec_pha_prof
		is
		begin
			return t_cls_pha_rs2xml.unSerializeProfessional(i_xml_prof => xmltype.createXML(xmlData => i_xml_prof));
		end unSerializeProfessional;
		--STATIC METHODS END

		member procedure resetCols
		is
		begin
			self.col_names.delete;
			self.col_data_types.delete;
			self.col_count := 0;
			self.row_count := 0;
			self.active_col_idx := 0;
			self.active_row_xpath := '';
			self.cur_sql_query := '';
		end resetCols;

		member procedure loadXML
		(
			i_xml	in	varchar2
		)
		is
		begin
			self.resetCols();
			self.xml_data := xmltype.createXML(xmlData => i_xml);
		end loadXML;

		member procedure loadXML
		(
			i_xml	in	clob
		)
		is
		begin
			self.resetCols();
			self.xml_data := xmltype.createXML(xmlData => i_xml);
		end loadXML;

		member procedure loadXML
		(
			i_id_xml		in	number,
			i_dblink_name	in	varchar2 default null
		)
		is
		begin
			self.resetCols();

			begin
				execute immediate 
					'
					SELECT a.xml_data 
					FROM pha_xml_data' || i_dblink_name || ' a 
					WHERE a.id_xml_data = :i_id_xml_data
					'
				into self.xml_data
				using in i_id_xml;
			exception
			when no_data_found then
				self.xml_data := null;
			end;

		end loadXML;

		member procedure extractColsFromXML
		is
			l_col_count		number := 0;
			l_col_name		varchar2(100 char);
			l_col_datatype	varchar2(100 char);
		begin
			self.resetCols();

			if (self.xml_data is not null) then
				self.active_row_xpath := '/' || self.tbl_name || '/HEADER/@COLS';
				l_col_count := self.xml_data.extract(self.active_row_xpath).getNumberVal();

				--get columns
				for i in 1 .. l_col_count
				loop
					self.active_row_xpath := '/' || self.tbl_name || '/HEADER/COL[' || i || ']/@NAME';
					l_col_name := self.xml_data.extract(self.active_row_xpath).getStringVal();
					self.active_row_xpath := '/' || self.tbl_name || '/HEADER/COL[' || i || ']/@DATATYPE';
					l_col_datatype := self.xml_data.extract(self.active_row_xpath).getStringVal();

					self.addCol(i_col_name => l_col_name, i_col_data_type => l_col_datatype);
				end loop;
			end if;

		end extractColsFromXML;

		member procedure genSQLExtractQuery
		is
		begin
			if (self.col_count > 0) then
				self.cur_sql_query := 'SELECT ';

				for i in 1 .. self.col_count
				loop
					if (i > 1) then
						self.cur_sql_query := self.cur_sql_query || ',';
					end if;

					case
						when (self.col_data_types(i) = self.C_DT_NUMBER) then
							self.cur_sql_query := self.cur_sql_query || 
									' to_number(EXTRACTVALUE(value(tbl), ''/ROW/' || self.col_names(i) || ''')) as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_VARCHAR2) then
							self.cur_sql_query := self.cur_sql_query || 
									' EXTRACTVALUE(value(tbl), ''/ROW/' || self.col_names(i) || ''') as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_TSTZ) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.unSerializeTSTZ(EXTRACTVALUE(value(tbl), ''/ROW/' || self.col_names(i) || ''')) as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_VARCHAR2_COLL) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.toVarchar2Collection(EXTRACT(value(tbl), ''/ROW/' || self.col_names(i) || '''), ''/' || self.col_names(i) || ''') as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_NUMBER_COLL) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.toNumberCollection(EXTRACT(value(tbl), ''/ROW/' || self.col_names(i) || '''), ''/' || self.col_names(i) || ''') as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_NUMBER_MATRIX) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.unSerializeTblTblNumber(EXTRACT(value(tbl), ''/ROW/' || self.col_names(i) || ''')) as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_VARCHAR2_MATRIX) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.unSerializeTblTblVarchar(EXTRACT(value(tbl), ''/ROW/' || self.col_names(i) || ''')) as ' || self.col_names(i);

						when (self.col_data_types(i) = self.C_DT_PROFESSIONAL) then
							self.cur_sql_query := self.cur_sql_query || 
									' t_cls_pha_rs2xml.unSerializeProfessional(EXTRACT(value(tbl), ''/ROW/' || self.col_names(i) || ''')) as ' || self.col_names(i);

						else
							--other
							self.cur_sql_query := self.cur_sql_query || ' EXTRACTVALUE(value(tbl), ''/ROW/' || self.col_names(i) || ''') as ' || self.col_names(i);
					end case;

				end loop;

				self.cur_sql_query := self.cur_sql_query || ' FROM TABLE(XMLSEQUENCE(EXTRACT(:xmldata, ''/' || self.tbl_name || '/ROWS/ROW''))) tbl ';

			else
				self.cur_sql_query := null;
			end if;

		end genSQLExtractQuery;

		member procedure getCursor
		(
			o_cur out sys_refcursor
		)
		is
		begin
			self.extractColsFromXML();
			self.genSQLExtractQuery();

			if (self.cur_sql_query is not null) then
				open o_cur for self.cur_sql_query using in self.xml_data;
			else
				pk_types.open_cursor_if_closed(i_cursor => o_cur);
			end if;

		end getCursor;

end;
/

set scan on;

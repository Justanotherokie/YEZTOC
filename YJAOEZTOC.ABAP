REPORT yjao_ez_toc.
**********************************************************************************
**********************************************************************************
*Name: Z_EZ_TOC
"13.11.2017 09:07:52  JAO
"Purpose: Streamline creating TOC Transports
* All work is done using stock SAP Function Modules not by directly accessing
* any Tables directly.
" Selection is based from FM 'TRINT_SELECT_REQUESTS'
* New transports are created using FM 'TR_REQUEST_MODIFY'
* Tasks objects are combined using FM 'TR_COPY_COMM'
* Child Objects are counted using FM 'TRINT_READ_REQUEST_WD'
*      SUBMIT rddprott AND RETURN
*             WITH pv_korr  = iv_object.

* Transport and Task Detals are presented using FM 'TR_PRESENT_REQUEST'
**********************************************************************************


*/INCLUDE yJAO_ez_lcl_def.

*&---------------------------------------------------------------------*
*&  Include           lcl_alv_base
*&---------------------------------------------------------------------*
"class lcl_alv_base  DEFINITION DEFERRED.
CLASS lcl_alv_fcat  DEFINITION DEFERRED.
CLASS lcl_alv_icons DEFINITION DEFERRED.
CLASS lcl_alv_icon  DEFINITION DEFERRED.
CLASS lcl_alv_tbar  DEFINITION DEFERRED.
CLASS lcl_alv_base  DEFINITION DEFERRED.

CLASS lcl_dom2vrm DEFINITION.

  PUBLIC SECTION.

    CLASS-METHODS elm_2_vrm
      IMPORTING
        !iv_name      TYPE string
      RETURNING
        VALUE(retval) TYPE vrm_values .
    CLASS-METHODS dom_2_vrm
      IMPORTING
        !iv_value     TYPE any
      RETURNING
        VALUE(retval) TYPE vrm_values .
    CLASS-METHODS set_vrm_listbox
      IMPORTING
        !iv_value     TYPE any
        !iv_name      TYPE string
      RETURNING
        VALUE(retval) TYPE sy-subrc .
ENDCLASS.


CLASS lcl_alv_tbar DEFINITION.



  PUBLIC SECTION.
    TYPE-POOLS cntb .

    TYPES:
      BEGIN OF ty_but,
        seq       TYPE i,
        function  TYPE ui_func,
        parent    TYPE ui_func,
        position  TYPE i,
        passthru  TYPE abap_bool,
        info      TYPE stb_button,
        base_icon TYPE icon_d,
      END OF ty_but .
    TYPES:
      ty_but_tab TYPE STANDARD TABLE OF ty_but .

    TYPE-POOLS abap .
    DATA mv_dirty TYPE abap_bool .
    DATA mt_but TYPE ty_but_tab .
    DATA mo_alv TYPE REF TO lcl_alv_base .
    DATA mo_icons TYPE REF TO lcl_alv_icons .

    METHODS constructor
      IMPORTING
        !io_alv TYPE REF TO lcl_alv_base .
    METHODS merge_tools
      CHANGING
        !ct_tbar TYPE ttb_button .
    METHODS add_cust_but
      IMPORTING
        !iv_function TYPE syucomm
        !iv_parent   TYPE syucomm OPTIONAL
        !iv_passthru TYPE abap_bool OPTIONAL
        !iv_text     TYPE string OPTIONAL
        !iv_position TYPE i OPTIONAL .
    METHODS add_separator
      IMPORTING iv_position TYPE i OPTIONAL.
    METHODS but_enable
      IMPORTING
        !iv_function TYPE syucomm .
    METHODS but_disable
      IMPORTING
        !iv_function TYPE syucomm .
    METHODS refresh .
    METHODS is_but_enabled
      IMPORTING
        !iv_function  TYPE syucomm
      RETURNING
        VALUE(retval) TYPE abap_bool .
    METHODS set_but_enabled
      IMPORTING
        !iv_function TYPE syucomm
        !iv_enabled  TYPE abap_bool .
    METHODS build_menu
      IMPORTING
        !iv_ucomm TYPE syucomm
        !io_menu  TYPE REF TO cl_ctmenu .
  PROTECTED SECTION.
  PRIVATE SECTION.

ENDCLASS.

CLASS lcl_alv_icons DEFINITION.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_icon_sub,
        icon_d TYPE icon_d,
        icon_q TYPE char80,
      END OF ty_icon_sub .
    TYPES:
      ty_icon_sub_tab TYPE HASHED TABLE OF ty_icon_sub
             WITH UNIQUE KEY icon_d .

    DATA mo_alv TYPE REF TO lcl_alv_base .

    METHODS has_icons
      RETURNING
        VALUE(retval) TYPE abap_bool .
    METHODS add_icon
      IMPORTING
        !iv_icon       TYPE icon_d
        !iv_qinfo_text TYPE string OPTIONAL
        !iv_function   TYPE syucomm OPTIONAL
        !iv_dtext      TYPE string OPTIONAL .
    METHODS get_icon
      IMPORTING
        !iv_icon      TYPE icon_d
      RETURNING
        VALUE(retval) TYPE REF TO lcl_alv_icon .
    METHODS fill_icon_sub_tab
      CHANGING
        !ct_sub TYPE ty_icon_sub_tab .
    METHODS get_function_icon
      IMPORTING
        !iv_function  TYPE syucomm
      RETURNING
        VALUE(retval) TYPE REF TO lcl_alv_icon .
    METHODS icon_exists
      IMPORTING
        !iv_icon      TYPE icon_d
      RETURNING
        VALUE(retval) TYPE icon_d .
    METHODS function_exists
      IMPORTING
        !iv_function  TYPE syucomm
      RETURNING
        VALUE(retval) TYPE abap_bool .
    METHODS constructor
      IMPORTING
        !io_alv TYPE REF TO lcl_alv_base OPTIONAL .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES:
      BEGIN OF ty_icon,
        function TYPE ui_func,
        icon     TYPE icon_d,
        iconobj  TYPE REF TO lcl_alv_icon,
      END OF ty_icon .
    TYPES:
      ty_icon_tab TYPE HASHED TABLE OF ty_icon
              WITH UNIQUE KEY primary_key COMPONENTS icon
              WITH NON-UNIQUE SORTED KEY function_key COMPONENTS function.
    DATA mt_data TYPE ty_icon_tab .

ENDCLASS.


CLASS lcl_alv_icon DEFINITION.

  PUBLIC SECTION.

    DATA mv_function TYPE ui_func .
    DATA mv_icon TYPE icon_d .
    DATA:
      mv_dtext(40)  TYPE c .
    DATA mv_qtext TYPE string .
    DATA mv_enc_icon TYPE char80 .

    CLASS-METHODS encode_icon
      IMPORTING
        !iv_icon       TYPE icon_d
        !iv_qinfo_text TYPE string
      RETURNING
        VALUE(retval)  TYPE char80 .
    METHODS constructor
      IMPORTING
        !iv_icon       TYPE icon_d
        !iv_qinfo_text TYPE string OPTIONAL
        !iv_function   TYPE syucomm OPTIONAL
        !iv_dtext      TYPE string OPTIONAL .
    METHODS create_button
      RETURNING
        VALUE(retval) TYPE stb_button .
  PROTECTED SECTION.
  PRIVATE SECTION.
ENDCLASS.

CLASS lcl_alv_fcat DEFINITION
  CREATE PUBLIC .

  PUBLIC SECTION.
    TYPE-POOLS zcalv .

    DATA mt_fcat TYPE lvc_t_fcat .
    DATA mt_ddic TYPE ddfields .
    DATA mv_ddic_avail TYPE abap_bool .
    DATA mv_ddic_name TYPE string .
    DATA mt_comp TYPE abap_component_tab .
    DATA mo_alv TYPE REF TO lcl_alv_base  .
    DATA mo_sdesc TYPE REF TO cl_abap_structdescr .
    CONSTANTS c_stru TYPE string VALUE 'CL_ABAP_STRUCTDESCR'. "#EC NOTEXT
    CONSTANTS c_tabl TYPE string VALUE 'CL_ABAP_TABLEDESCR'. "#EC NOTEXT

    CLASS-METHODS create_by_data
      IMPORTING
        !is_data      TYPE any
        !io_alv       TYPE REF TO lcl_alv_base OPTIONAL
      RETURNING
        VALUE(retval) TYPE REF TO lcl_alv_fcat .
    CLASS-METHODS create_by_name
      IMPORTING
        !iv_name      TYPE string
        !io_alv       TYPE REF TO lcl_alv_base OPTIONAL
      RETURNING
        VALUE(retval) TYPE REF TO lcl_alv_fcat .
    CLASS-METHODS get_table_comp
      IMPORTING
        !it_data      TYPE STANDARD TABLE
      RETURNING
        VALUE(retval) TYPE abap_component_tab .
    CLASS-METHODS get_struct_comp
      IMPORTING
        !is_data      TYPE any
      RETURNING
        VALUE(retval) TYPE abap_component_tab .
    CLASS-METHODS get_colheads
      IMPORTING
        !iv_name      TYPE string
        !iv_head_type TYPE string OPTIONAL
      RETURNING
        VALUE(retval) TYPE string .
    CLASS-METHODS get_table_defn
      IMPORTING
        !it_data      TYPE STANDARD TABLE
      RETURNING
        VALUE(retval) TYPE ddfields .
    CLASS-METHODS get_struct_flds
      IMPORTING
        !is_data      TYPE any
      RETURNING
        VALUE(retval) TYPE ddfields .
    METHODS constructor
      IMPORTING
        !io_alv   TYPE REF TO lcl_alv_base OPTIONAL
        !io_sdesc TYPE REF TO cl_abap_structdescr .
    METHODS build_fcat
      IMPORTING
        !iv_auto TYPE abap_bool DEFAULT 'X'
        !iv_min  TYPE abap_bool OPTIONAL .
    METHODS apply_properties .
    METHODS set_property
      IMPORTING
        !iv_fieldname TYPE string
        !iv_propname  TYPE string
        !iv_propvalue TYPE string .
    METHODS is_fcat_dirty
      RETURNING
        VALUE(retval) TYPE abap_bool .
  PROTECTED SECTION.
  PRIVATE SECTION.
    TYPES: BEGIN OF ty_fcat_prop,
             seq       TYPE i,
             fieldname TYPE lvc_fname,
             propname  TYPE fieldname,
             propvalue TYPE string,
           END OF ty_fcat_prop,
           ty_fcat_prop_tab TYPE STANDARD TABLE OF ty_fcat_prop.
    DATA mt_fcat_prop TYPE ty_fcat_prop_tab.
ENDCLASS.


CLASS lcl_alv_base DEFINITION
  INHERITING FROM cl_gui_alv_grid
  ABSTRACT.

  PUBLIC SECTION.
    TYPE-POOLS zcalv .
    CONSTANTS:
      BEGIN OF c_alv,
        cfieldname     TYPE string VALUE 'CFIELDNAME' ##NO_TEXT, "Field name for currency unit referenced
        checkbox       TYPE string VALUE 'CHECKBOX'   ##NO_TEXT, "Output as checkbox
        col_id         TYPE string VALUE 'COL_ID'     ##NO_TEXT, "Numerical column identification (read-only)
        col_pos        TYPE string VALUE 'COL_POS'    ##NO_TEXT, "Position of output column
        colddictxt     TYPE string VALUE 'COLDDICTXT' ##NO_TEXT, "Definition of DDIC text reference
        coltext        TYPE string VALUE 'COLTEXT'    ##NO_TEXT, "Column label for dialog functions
        currency       TYPE string VALUE 'CURRENCY'   ##NO_TEXT, "Currency unit
        dd_outlen      TYPE string VALUE 'DD_OUTLEN'  ##NO_TEXT, "Output length in characters
        decimals_o     TYPE string VALUE 'DECIMALS_O' ##NO_TEXT, "Number of decimal places for output
        decmlfield     TYPE string VALUE 'DECMLFIELD' ##NO_TEXT, "Field name with DECIMALS specification
        do_sum         TYPE string VALUE 'DO_SUM'     ##NO_TEXT, "Totals calculation for column Values
        dragdropid     TYPE string VALUE 'DRAGDROPID' ##NO_TEXT, "Drag & Drop handle for Drag & Drop object
        edit_mask      TYPE string VALUE 'EDIT_MASK'  ##NO_TEXT, "EditMask for output
        emphasize      TYPE string VALUE 'EMPHASIZE'  ##NO_TEXT, "Column color
        exponent       TYPE string VALUE 'EXPONENT'   ##NO_TEXT, "Exponent for float representation
        fieldname      TYPE string VALUE 'FIELDNAME'  ##NO_TEXT, "Field name of internal table field
        hotspot        TYPE string VALUE 'HOTSPOT'    ##NO_TEXT, "Single-click sensitive
        href_hndle     TYPE string VALUE 'HREF_HNDLE' ##NO_TEXT, "Assign hyperlink
        icon           TYPE string VALUE 'ICON'       ##NO_TEXT, "Output as icon
        intlen         TYPE string VALUE 'INTLEN'     ##NO_TEXT, "Internal length in bytes
        inttype        TYPE string VALUE 'INTTYPE'    ##NO_TEXT, "ABAP data  type (C,D,N,...)
        just           TYPE string VALUE 'JUST'       ##NO_TEXT, "Justification
        key            TYPE string VALUE 'KEY'        ##NO_TEXT, "Key column
        lowercase      TYPE string VALUE 'LOWERCASE'  ##NO_TEXT, "Lower case allowed/not allowed
        lzero          TYPE string VALUE 'LZERO'      ##NO_TEXT, "Display leading zeros
        no_merging     TYPE string VALUE 'NO_MERGING' ##NO_TEXT, "Do not merge cells
        no_out         TYPE string VALUE 'NO_OUT'     ##NO_TEXT, "Do not display columns
        no_sign        TYPE string VALUE 'NO_SIGN'    ##NO_TEXT, "Supress sign in display
        no_sum         TYPE string VALUE 'NO_SUM'     ##NO_TEXT, "No totals calculation for column Values
        no_zero        TYPE string VALUE 'NO_ZERO'    ##NO_TEXT, "Suppress zeros in display
        outputlen      TYPE string VALUE 'OUTPUTLEN'  ##NO_TEXT, "Column width in characters
        qfieldname     TYPE string VALUE 'QFIELDNAME' ##NO_TEXT, "Field name for quantity unit referenced
        quantity       TYPE string VALUE 'QUANTITY'   ##NO_TEXT, "Quantity unit
        ref_field      TYPE string VALUE 'REF_FIELD'  ##NO_TEXT, "Reference field name for internal table field
        ref_table      TYPE string VALUE 'REF_TABLE'  ##NO_TEXT, "Reference table name for internal table field
        reprep         TYPE string VALUE 'REPREP'     ##NO_TEXT, "Property is selection criterion for report/report interface
        reptext        TYPE string VALUE 'REPTEXT'    ##NO_TEXT, "Header (DDIC text of the corresponding data element)
        rollname       TYPE string VALUE 'ROLLNAME'   ##NO_TEXT, "Data element for F1 help
        round          TYPE string VALUE 'ROUND'      ##NO_TEXT, "ROUND Value
        roundfield     TYPE string VALUE 'ROUNDFIELD' ##NO_TEXT, "Field name with ROUND specification
        scrtext_l      TYPE string VALUE 'SCRTEXT_L'  ##NO_TEXT, "Long field label (DDIC text of the corresponding data element)
        scrtext_m      TYPE string VALUE 'SCRTEXT_M'  ##NO_TEXT, "Medium field label (DDIC text of the corresponding data element)
        scrtext_s      TYPE string VALUE 'SCRTEXT_S'  ##NO_TEXT, "Short field label (DDIC text of the corresponding data element)
        selddictxt     TYPE string VALUE 'SELDDICTXT' ##NO_TEXT, "Definition of DDIC text reference
        seltext        TYPE string VALUE 'SELTEXT'    ##NO_TEXT, "Column label for dialog function
        sp_group       TYPE string VALUE 'SP_GROUP'   ##NO_TEXT, "Group key
        style          TYPE string VALUE 'STYLE'      ##NO_TEXT, "Output as pushbutton
        symbol         TYPE string VALUE 'SYMBOL'     ##NO_TEXT, "Output as symbol
        tech           TYPE string VALUE 'TECH'       ##NO_TEXT, "Technical fields
        tipddictxt     TYPE string VALUE 'TIPDDICTXT' ##NO_TEXT, "Definition of DDIC text reference
        tooltip        TYPE string VALUE 'TOOLTIP'    ##NO_TEXT, "Tool tip for column header
        txt_field      TYPE string VALUE 'TXT_FIELD'  ##NO_TEXT, "Field name of internal table field
        web_field      TYPE string VALUE 'WEB_FIELD'  ##NO_TEXT, "Field name of internal table field (for hyperlink)
        href_hndl      TYPE string VALUE 'HREF_HNDL'      ##NO_TEXT,    "Natural Number
        style2         TYPE string VALUE 'STYLE2'         ##NO_TEXT,    "ALV control: Style
        style3         TYPE string VALUE 'STYLE3'         ##NO_TEXT,    "ALV control: Style
        style4         TYPE string VALUE 'STYLE4'         ##NO_TEXT,    "ALV control: Style
        drdn_hndl      TYPE string VALUE 'DRDN_HNDL'      ##NO_TEXT,    "Natural Number
        drdn_field     TYPE string VALUE 'DRDN_FIELD'     ##NO_TEXT,    "ALV control: Field name of internal table field
        h_ftype        TYPE string VALUE 'H_FTYPE'        ##NO_TEXT,    "ALV tree control: Functional type (sum, avg, max, min, ...)
        col_opt        TYPE string VALUE 'COL_OPT'        ##NO_TEXT,    "Entry for Optional Column Optimization
        no_init_ch     TYPE string VALUE 'NO_INIT_CH'     ##NO_TEXT,    "Character Field Length 1
        drdn_alias     TYPE string VALUE 'DRDN_ALIAS'     ##NO_TEXT,    "Character Field Length 1
        decfloat_style TYPE string VALUE 'DECFLOAT_STYLE' ##NO_TEXT,    "DD: Output Style (Output Style) for Decfloat Types                        END OF c_alv.
      END OF c_alv .
    CONSTANTS: BEGIN OF c_alv_color,
                 none      TYPE num1 VALUE 0,  "No Color
                 blue      TYPE num1 VALUE 1,
                 gray      TYPE num1 VALUE 2,
                 yellow    TYPE num1 VALUE 3,
                 bluegray  TYPE num1 VALUE 4,
                 green     TYPE num1 VALUE 5,
                 red       TYPE num1 VALUE 6,
                 buttersch TYPE num1 VALUE 7,
               END OF c_alv_color.

    DATA ms_layo TYPE lvc_s_layo .
    DATA mt_f4_help TYPE lvc_t_f4 .
    DATA mo_fcat TYPE REF TO lcl_alv_fcat .
    DATA mo_icons TYPE REF TO lcl_alv_icons .
    DATA mo_tbar TYPE REF TO lcl_alv_tbar .
    DATA gt_sort TYPE lvc_t_sort .

    EVENTS custom_setup .

    CLASS-METHODS get_alv_color
      IMPORTING
                iv_color      TYPE num1
                iv_intensity  TYPE any DEFAULT '1'
                iv_inverse    TYPE any DEFAULT '0'
      RETURNING VALUE(retval) TYPE char4.

    METHODS add_sort
      IMPORTING
        !iv_fieldname TYPE string
        !iv_sort      TYPE any DEFAULT 'A' .   "A = Ascending D=Descending
    METHODS push_to_sapgui
      IMPORTING
        !iv_function TYPE sy-ucomm .
    METHODS set_delay_selection
      IMPORTING
        !iv_delay TYPE i .
    METHODS set_delay_cell_chg
      IMPORTING
        !iv_delay TYPE i .
    METHODS set_fcat
      IMPORTING
        !iv_fieldname TYPE string
        !iv_propname  TYPE string
        !iv_propvalue TYPE string .
    METHODS set_fcat_many
      IMPORTING
        !iv_fieldname TYPE string
        !iv_propname  TYPE string
        !iv_propvalue TYPE string .
    METHODS constructor
      IMPORTING
        !i_data      TYPE any
        !iv_dynnr    TYPE sy-dynnr OPTIONAL
        !io_parent   TYPE REF TO cl_gui_container OPTIONAL
        !iv_lifetime TYPE i OPTIONAL
      RAISING
        zcx_cop_alv_exception .
    METHODS display
      IMPORTING
        VALUE(is_variant) TYPE disvariant OPTIONAL
        VALUE(iv_save)    TYPE char01 OPTIONAL
        VALUE(iv_default) TYPE char01 DEFAULT 'X'
        VALUE(is_layout)  TYPE lvc_s_layo OPTIONAL
      CHANGING
        !ct_data          TYPE STANDARD TABLE .

    METHODS get_first_selected_row
      RETURNING
        VALUE(retval) TYPE i
      RAISING
        zcx_cop_alv_exception .
    METHODS get_layout
      RETURNING
        VALUE(retval) TYPE lvc_s_layo .
    METHODS get_selected_row_count
      RETURNING
        VALUE(retval) TYPE i .
    METHODS get_selected_rowsv
      RETURNING
        VALUE(retval) TYPE REF TO lvc_t_roid
      RAISING
        zcx_cop_alv_exception .
    METHODS get_selected_data
      CHANGING
        !ct_table TYPE STANDARD TABLE
      RAISING
        zcx_cop_alv_exception .
    METHODS get_first_selected_rowdata
      CHANGING
        !cs_data TYPE any
      RAISING
        zcx_cop_alv_exception .
    METHODS is_row_selected
      IMPORTING
        !iv_row       TYPE i
      RETURNING
        VALUE(retval) TYPE i
      RAISING
        zcx_cop_alv_exception .
    METHODS get_active_row
      RETURNING
        VALUE(retval) TYPE i
      RAISING
        zcx_cop_alv_exception .
    METHODS get_active_cellid
      RETURNING
        VALUE(retval) TYPE string .
    METHODS get_active_celldata
      RETURNING
        VALUE(retval) TYPE REF TO data .
    METHODS get_active_col
      RETURNING
        VALUE(retval) TYPE i
      RAISING
        zcx_cop_alv_exception .
    METHODS set_active_cell
      IMPORTING
        !iv_row     TYPE i
        !iv_colname TYPE string
      RAISING
        zcx_cop_alv_exception .
    METHODS set_active_row
      IMPORTING
        !iv_row TYPE i
      RAISING
        zcx_cop_alv_exception .
    METHODS is_row_valid
      IMPORTING
        !iv_row       TYPE i
      RETURNING
        VALUE(retval) TYPE abap_bool .
    METHODS get_rowdata
      IMPORTING
        !iv_row  TYPE i
      CHANGING
        !cs_data TYPE any
      RAISING
        zcx_cop_alv_exception .
    METHODS get_active_rowdata
      CHANGING
        !cs_data TYPE any
      RAISING
        zcx_cop_alv_exception .
    METHODS add_f4_help_item
      IMPORTING
        !iv_fieldname  TYPE lvc_fname
        !iv_getbefore  TYPE lvc_compl OPTIONAL
        !iv_chngeafter TYPE lvc_compl OPTIONAL
        !iv_internal   TYPE lvc_inter OPTIONAL
        !iv_register   TYPE lvc_regis DEFAULT 'X' .
    METHODS on_onf1
          FOR EVENT onf1 OF cl_gui_alv_grid
      IMPORTING
          !e_fieldname
          !es_row_no
          !er_event_data .
    METHODS on_onf4
          FOR EVENT onf4 OF cl_gui_alv_grid
      IMPORTING
          !e_fieldname
          !e_fieldvalue
          !es_row_no
          !er_event_data
          !et_bad_cells
          !e_display .
    METHODS on_data_changed
          FOR EVENT data_changed OF cl_gui_alv_grid
      IMPORTING
          !er_data_changed
          !e_onf4
          !e_onf4_before
          !e_onf4_after
          !e_ucomm .
    METHODS on_ondropgetflavor
          FOR EVENT ondropgetflavor OF cl_gui_alv_grid
      IMPORTING
          !e_row
          !e_column
          !es_row_no
          !e_dragdropobj
          !e_flavors .
    METHODS on_ondrag
          FOR EVENT ondrag OF cl_gui_alv_grid
      IMPORTING
          !e_row
          !e_column
          !es_row_no
          !e_dragdropobj .
    METHODS on_ondrop
          FOR EVENT ondrop OF cl_gui_alv_grid
      IMPORTING
          !e_row
          !e_column
          !es_row_no
          !e_dragdropobj .
    METHODS on_ondropcomplete
          FOR EVENT ondropcomplete OF cl_gui_alv_grid
      IMPORTING
          !e_row
          !e_column
          !es_row_no
          !e_dragdropobj .
    METHODS on_subtotal_text
          FOR EVENT subtotal_text OF cl_gui_alv_grid
      IMPORTING
          !es_subtottxt_info
          !ep_subtot_line
          !e_event_data .
    METHODS on_before_user_command
          FOR EVENT before_user_command OF cl_gui_alv_grid
      IMPORTING
          !e_ucomm .
    METHODS on_user_command
          FOR EVENT user_command OF cl_gui_alv_grid
      IMPORTING
          !e_ucomm .
    METHODS on_after_user_command
          FOR EVENT after_user_command OF cl_gui_alv_grid
      IMPORTING
          !e_ucomm
          !e_saved
          !e_not_processed .
    METHODS on_double_click
          FOR EVENT double_click OF cl_gui_alv_grid
      IMPORTING
          !e_row
          !e_column
          !es_row_no .
    METHODS on_delayed_cell
        FOR EVENT delayed_callback OF cl_gui_alv_grid .
    METHODS on_delayed_sel
        FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid .
    METHODS on_print_top_of_page
          FOR EVENT print_top_of_page OF cl_gui_alv_grid
      IMPORTING
          !table_index .
    METHODS on_print_top_of_list
        FOR EVENT print_top_of_list OF cl_gui_alv_grid .
    METHODS on_print_end_of_page
        FOR EVENT print_end_of_page OF cl_gui_alv_grid .
    METHODS on_print_end_of_list
        FOR EVENT print_end_of_list OF cl_gui_alv_grid .
    METHODS on_top_of_page
          FOR EVENT top_of_page OF cl_gui_alv_grid
      IMPORTING
          !e_dyndoc_id
          !table_index .
    METHODS on_context_menu_request
          FOR EVENT context_menu_request OF cl_gui_alv_grid
      IMPORTING
          !e_object .
    METHODS on_menu_button
          FOR EVENT menu_button OF cl_gui_alv_grid
      IMPORTING
          !e_object
          !e_ucomm .
    METHODS on_toolbar
          FOR EVENT toolbar OF cl_gui_alv_grid
      IMPORTING
          !e_object
          !e_interactive .
    METHODS on_hotspot_click
          FOR EVENT hotspot_click OF cl_gui_alv_grid
      IMPORTING
          !e_row_id
          !e_column_id
          !es_row_no .
    METHODS on_end_of_list
          FOR EVENT end_of_list OF cl_gui_alv_grid
      IMPORTING
          !e_dyndoc_id .
    METHODS on_after_refresh
        FOR EVENT after_refresh OF cl_gui_alv_grid .
    METHODS on_button_click
          FOR EVENT button_click OF cl_gui_alv_grid
      IMPORTING
          !es_col_id
          !es_row_no .
    METHODS on_data_changed_finished
          FOR EVENT data_changed_finished OF cl_gui_alv_grid
      IMPORTING
          !e_modified
          !et_good_cells .
    METHODS on_drop_external_files
          FOR EVENT drop_external_files OF cl_gui_alv_grid
      IMPORTING
          !files .
    METHODS qinfo_add_icon
      IMPORTING
        !iv_icon       TYPE icon_d
        !iv_qinfo_text TYPE char50 .
    METHODS qinfo_get_icon_obj
      IMPORTING
        !iv_icon      TYPE icon_d
      RETURNING
        VALUE(retval) TYPE REF TO lcl_alv_icon .
    METHODS qinfo_get_icon
      IMPORTING
        !iv_icon      TYPE icon_d
      RETURNING
        VALUE(retval) TYPE char80 .
    METHODS on_cell_changed
        FOR EVENT delayed_callback OF cl_gui_alv_grid .
    METHODS on_selection_changed
        FOR EVENT delayed_changed_sel_callback OF cl_gui_alv_grid .
    METHODS set_header_html
      IMPORTING
        !iv_htmltext TYPE string .
    METHODS get_header_html
      RETURNING
        VALUE(retval) TYPE string .
    METHODS get_default_toolbar
      RETURNING
        VALUE(retval) TYPE string .
    METHODS set_default_toolbar
      IMPORTING
        !iv_toolbar TYPE string .
    METHODS get_okcode
      RETURNING
        VALUE(retval) TYPE syucomm .
  PROTECTED SECTION.
    DATA mr_data TYPE REF TO data.
    DATA mv_html_hdr TYPE string.
    DATA mv_html_hdr_dirty TYPE abap_bool.
    DATA mv_okcode  TYPE sy-ucomm.
    METHODS default_layout.

  PRIVATE SECTION.
    DATA mv_first_display TYPE abap_bool VALUE abap_true.
    DATA mv_default_toolbar TYPE string .

ENDCLASS.


CLASS lcl_alv DEFINITION INHERITING FROM lcl_alv_base.

  PUBLIC SECTION.
    TYPES: BEGIN OF ty_alvdata,
             row_color(4)   TYPE c,
             row_icon       TYPE char80,
             trstatustext   TYPE string,
             trstatus       TYPE e070-trstatus,
             strkorr        TYPE e070-strkorr,
             trkorr         TYPE e070-trkorr,
             trfunction     TYPE trfunction,
             trfunctiontext TYPE string,
             tarsystem      TYPE e070-tarsystem,
             as4user        TYPE e070-as4user,
             as4date        TYPE e070-as4date,
             as4time        TYPE e070-as4time,
             as4text        TYPE e070v-as4text,
             client         TYPE e070v-client,
             trfunkey       TYPE string,
             trstatkey      TYPE string,
             groupkey(5)    TYPE c,
             sortseq        TYPE i,
             parent         TYPE trwbo_request_header,
             childcnt       TYPE i,
             children       TYPE strhi_request_wd,
           END OF ty_alvdata,
           ty_alvdata_tab TYPE STANDARD TABLE OF ty_alvdata.

    TYPES: BEGIN OF ty_sel_state,
             none        TYPE abap_bool,
             new_target  TYPE abap_bool,
             target      TYPE trkorr,
             sources     TYPE trkorrs,
             src_cnt     TYPE i,
             src_obj_cnt TYPE i,
             src_text    TYPE string,
             tar_obj_cnt TYPE i,
             mod_toc_cnt TYPE i,
             msg_text    TYPE string,
             sel_cnt     TYPE i,
             single_toc  TYPE trkorr,
           END OF ty_sel_state.

    DATA gt_alvdata TYPE ty_alvdata_tab.
    DATA gt_reqhdr  TYPE trwbo_request_headers.
    DATA gs_ranges  TYPE trsel_ts_ranges.
    DATA gv_curr_target       TYPE trkorr.
    DATA gv_has_target        TYPE abap_bool.
    DATA gv_grid_title        TYPE string.
    DATA gv_save_message      TYPE string.
    DATA gv_save_message_type TYPE c.
    DATA gv_force_refresh     TYPE abap_bool.

    METHODS constructor
      IMPORTING iv_dynnr TYPE sy-dynnr
      RAISING   zcx_cop_alv_exception.
    METHODS open.
    METHODS append_request IMPORTING iv_trkorr TYPE trkorr.
    METHODS create_request RETURNING VALUE(retval) TYPE trkorr.
    METHODS new_toc RETURNING VALUE(retval) TYPE abap_bool.
    METHODS present_request IMPORTING iv_trkorr TYPE any.
    METHODS get_children
      IMPORTING iv_trkorr     TYPE any
      RETURNING VALUE(retval) TYPE strhi_request_wd.
    METHODS fill_tr_meta_data CHANGING cs_alvdata TYPE ty_alvdata.
    METHODS refresh_data.
    METHODS display_log.
    METHODS update_ui.
    METHODS init_buttons.
    METHODS set_target RETURNING VALUE(retval) TYPE abap_bool.
    METHODS restore_selection IMPORTING it_alvdata TYPE ty_alvdata_tab.
    METHODS get_sel_state
      IMPORTING iv_target     TYPE trkorr
      RETURNING VALUE(retval) TYPE ty_sel_state
      RAISING   zcx_cop_alv_exception.
    METHODS re_display IMPORTING iv_restore_sel TYPE abap_bool OPTIONAL.

    METHODS on_print_top_of_list REDEFINITION.
    METHODS on_selection_changed REDEFINITION.
    METHODS on_double_click REDEFINITION.
    METHODS on_cell_changed REDEFINITION.
    METHODS on_user_command REDEFINITION.
    METHODS on_custom_setup FOR EVENT custom_setup OF lcl_alv_base.
*    CLASS-METHODS mask_tcode.
*    CLASS-METHODS unmask_tcode.
  PROTECTED SECTION.
    DATA gt_func TYPE vrm_values.
    DATA gt_stat TYPE vrm_values.

ENDCLASS.


TABLES e070.
DATA go_alv     TYPE REF TO lcl_alv.
DATA gv_0100_ok TYPE sy-ucomm.
DATA gv_save_ok TYPE sy-ucomm.
DATA gs_ranges  TYPE trsel_ts_ranges.
DATA gs_init_tcode TYPE sy-tcode.

DATA gv_save_tcode TYPE sy-tcode.
DATA gv_save_dynnr TYPE sy-dynnr.

SELECTION-SCREEN BEGIN OF BLOCK b1  WITH FRAME TITLE titlb1.
SELECT-OPTIONS s_s4user  FOR  e070-as4user    NO INTERVALS.
SELECT-OPTIONS s_s4date  FOR  e070-as4date.
SELECT-OPTIONS s_strkor  FOR  e070-trkorr.
SELECT-OPTIONS s_trfunc  FOR  e070-trfunction NO INTERVALS.
SELECT-OPTIONS s_status  FOR  e070-trstatus   NO INTERVALS.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF BLOCK b3  WITH FRAME TITLE titlb3.
PARAMETERS     p_myopen  TYPE abap_bool DEFAULT abap_true AS CHECKBOX.
PARAMETERS     p_text    TYPE e07t-as4text.
SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN SKIP.

SELECTION-SCREEN BEGIN OF BLOCK b2  WITH FRAME TITLE titlb2.
PARAMETERS     p_tarsys  TYPE e070-tarsystem DEFAULT 'ETQ.010' OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b2.


LOAD-OF-PROGRAM.
  GET PARAMETER ID 'TCD' FIELD gs_init_tcode. " The initial TCODE name
  PERFORM init_selscr.

INITIALIZATION.
  %_s_s4user_%_app_%-text = 'Include owner(s)'.
  %_s_s4date_%_app_%-text = 'Date'.
  %_s_strkor_%_app_%-text = 'Request/task Number'.
  %_s_trfunc_%_app_%-text = 'Type of request/task'.
  %_s_status_%_app_%-text = 'Status'.
  %_p_tarsys_%_app_%-text = 'TOC Target System'.
  %_p_myopen_%_app_%-text  = 'All modifiable requests/tasks'.
  %_p_text_%_app_%-text    = 'When title text contains text'.
  gv_save_tcode = sy-tcode.
  gv_save_dynnr = sy-dynnr.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_TARSYS'.
*       screen-input = '0'.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_tarsys.
*  lcl_alv=>mask_tcode( ).


START-OF-SELECTION.
*  lcl_alv=>unmask_tcode( ).
  PERFORM display_data.

END-OF-SELECTION.

*&---------------------------------------------------------------------*
*&      Module  0100_PAI  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 0100_pai INPUT.

  PERFORM pai_0100.

ENDMODULE.                 " 0100_PAI  INPUT


*&---------------------------------------------------------------------*
*&      Module  0100_PBO  OUTPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE 0100_pbo OUTPUT.

  SET TITLEBAR 'TITLE_0100'.
  SET PF-STATUS 'STATUS_0100'.
  TRY.
      IF go_alv IS NOT BOUND.  "Check if first time through
        "Link ALV to blank Screen
        CREATE OBJECT go_alv EXPORTING iv_dynnr = '0100' .
        go_alv->gs_ranges = gs_ranges.
      ENDIF.
      go_alv->re_display( ).
    CATCH  zcx_cop_alv_exception.
      EXIT.
  ENDTRY.
ENDMODULE.

FORM init_selscr.
  " initialize selection screen
  APPEND INITIAL LINE TO s_s4user ASSIGNING FIELD-SYMBOL(<usr>).
  <usr>-low    = sy-uname.
  <usr>-option = 'EQ'.
  <usr>-sign   = 'I'.
  APPEND INITIAL LINE TO s_s4date ASSIGNING FIELD-SYMBOL(<dat>).
  <dat>-low    = sy-datum - 30.
  <dat>-high   = '99991231'.
  <dat>-option = 'BT'.
  <dat>-sign   = 'I'.
  APPEND INITIAL LINE TO s_trfunc ASSIGNING FIELD-SYMBOL(<fun>).
  <fun>-low    = 'K'.
  <fun>-option = 'EQ'.
  <fun>-sign   = 'I'.
  APPEND INITIAL LINE TO s_trfunc ASSIGNING <fun>.
  <fun>-low    = 'T'.
  <fun>-option = 'EQ'.
  <fun>-sign   = 'I'.
  APPEND INITIAL LINE TO s_trfunc ASSIGNING <fun>.
  <fun>-low    = 'W'.
  <fun>-option = 'EQ'.
  <fun>-sign   = 'I'.
  APPEND INITIAL LINE TO s_trfunc ASSIGNING <fun>.
  <fun>-low    = 'Q'.
  <fun>-option = 'EQ'.
  <fun>-sign   = 'I'.


  titlb1 = 'Source Transports'.
  titlb2 = 'TOC Target System'.
  titlb3 = 'In addition to standard selections include'.

ENDFORM.


FORM display_data.

  CLEAR gs_ranges.
  gs_ranges-as4date[] = s_s4date[].
  gs_ranges-as4user[] = s_s4user[].
  gs_ranges-trkorr[] = s_strkor[].
  gs_ranges-request_status[] = s_status[].
  gs_ranges-request_funcs[] = s_trfunc[].
  CALL SCREEN 0100.

ENDFORM.
FORM pai_0100.
  " Workaround for Push through OK Codes.
  IF gv_0100_ok IS INITIAL.
    gv_0100_ok = go_alv->get_okcode( ).
  ELSE.
    gv_save_ok = gv_0100_ok.
  ENDIF.

  CLEAR gv_0100_ok.
  CASE gv_save_ok.
    WHEN 'BACK' OR 'CANCEL'.
      IF sy-tcode+0(1) CA 'YZ'.
        LEAVE TO TRANSACTION sy-tcode.
      ELSE.
        LEAVE TO SCREEN 0.
      ENDIF.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
  ENDCASE.

ENDFORM.

*/INCLUDE yJAO_ez_lcl_imp.




CLASS lcl_alv_tbar IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->ADD_CUST_BUT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* | [--->] IV_PARENT                      TYPE        SYUCOMM(optional)
* | [--->] IV_PASSTHRU                    TYPE        ABAP_BOOL(optional)
* | [--->] IV_TEXT                        TYPE        STRING(optional)
* | [--->] IV_POSITION                    TYPE        I(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_cust_but.
    FIELD-SYMBOLS <but> TYPE ty_but.
    FIELD-SYMBOLS <butp> TYPE ty_but.
    DATA lo_icon TYPE REF TO lcl_alv_icon.
    APPEND INITIAL LINE TO mt_but ASSIGNING <but>.
    lo_icon = mo_icons->get_function_icon( iv_function ).
    IF lo_icon IS BOUND.
      <but>-info = lo_icon->create_button( ).
      <but>-base_icon = lo_icon->mv_icon.
    ELSE.
      <but>-info-text = iv_text.
      <but>-info-function = iv_function.
    ENDIF.
    <but>-function = iv_function.
    <but>-parent   = iv_parent.
    <but>-seq = lines( mt_but ).
    <but>-passthru = iv_passthru.
    <but>-position = iv_position.

    IF <but>-parent IS NOT INITIAL.
      READ TABLE mt_but ASSIGNING <butp>
        WITH KEY function = iv_parent.
      IF sy-subrc = 0.
        <butp>-info-butn_type = cntb_btype_dropdown.
      ENDIF.
    ENDIF.
    mv_dirty = abap_true.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->ADD_SEPARATOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_POSITION                    TYPE        I(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_separator.

    APPEND INITIAL LINE TO mt_but ASSIGNING FIELD-SYMBOL(<but>).
    <but>-position = iv_position.
    <but>-info-butn_type = '3'.
    <but>-seq = lines( mt_but ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->BUILD_MENU
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_UCOMM                       TYPE        SYUCOMM
* | [--->] IO_MENU                        TYPE REF TO CL_CTMENU
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD build_menu.
    DATA lt_but TYPE ty_but_tab .
    FIELD-SYMBOLS <but> TYPE ty_but.
    CHECK iv_ucomm IS NOT INITIAL.
    lt_but[] = mt_but[].
    DELETE lt_but WHERE parent <> iv_ucomm.
    SORT lt_but BY seq.
    LOOP AT lt_but ASSIGNING <but>.
*      lv_base_icon = mo_icons->get_base_icon( iv_ucomm ).
      io_menu->add_function(
        EXPORTING fcode = <but>-info-function
                  disabled = <but>-info-disabled
                  icon = <but>-base_icon
                  text = <but>-info-text ).
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->BUT_DISABLE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD but_disable.
    set_but_enabled( iv_function = iv_function iv_enabled = abap_false ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->BUT_ENABLE
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD but_enable.
    set_but_enabled( iv_function = iv_function iv_enabled = abap_true ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_ALV                         TYPE REF TO lcl_ALV_BASE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    mo_alv = io_alv.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->IS_BUT_ENABLED
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* | [<-()] RETVAL                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD is_but_enabled.
    FIELD-SYMBOLS <but> TYPE ty_but.
    retval = abap_false.
    READ TABLE mt_but ASSIGNING <but>
      WITH KEY function = iv_function.
    IF sy-subrc = 0.
      IF <but>-info-disabled = abap_false.
        retval = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->MERGE_TOOLS
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_TBAR                        TYPE        TTB_BUTTON
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD merge_tools.
    TYPES: BEGIN OF ty_ucomm,
             ucomm TYPE syucomm,
           END OF ty_ucomm,
           ty_ucomm_tab TYPE STANDARD TABLE OF ty_ucomm.

    FIELD-SYMBOLS: <tbar> TYPE stb_button.
    FIELD-SYMBOLS: <but> TYPE ty_but.
    DATA lt_deftb TYPE ty_ucomm_tab.
    DATA lv_ndx TYPE i.
    SPLIT mo_alv->get_default_toolbar( ) AT ',' INTO TABLE lt_deftb.
    SORT lt_deftb.

    IF lines( lt_deftb ) > 0.
      LOOP AT ct_tbar ASSIGNING <tbar>.
        lv_ndx = sy-tabix.
        READ TABLE lt_deftb TRANSPORTING NO FIELDS
          WITH KEY ucomm = <tbar>-function
            BINARY SEARCH.
        IF sy-subrc <> 0.
          DELETE ct_tbar INDEX lv_ndx.
        ENDIF.
      ENDLOOP.
    ENDIF.
    LOOP AT mt_but ASSIGNING <but>.
      IF <but>-parent IS INITIAL.
        INSERT <but>-info INTO ct_tbar  INDEX <but>-seq.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->REFRESH
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD refresh.
    mo_alv->set_toolbar_interactive( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_TBAR->SET_BUT_ENABLED
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* | [--->] IV_ENABLED                     TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_but_enabled.
    FIELD-SYMBOLS <but> TYPE ty_but.
    READ TABLE mt_but ASSIGNING <but>
      WITH KEY function = iv_function.
    IF sy-subrc = 0.
      mv_dirty = abap_true.
      IF iv_enabled = abap_true.
        <but>-info-disabled = abap_false.
      ELSE.
        <but>-info-disabled = abap_true.
      ENDIF.
    ENDIF.
  ENDMETHOD.
ENDCLASS.



CLASS lcl_alv_icons IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->ADD_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [--->] IV_QINFO_TEXT                  TYPE        STRING(optional)
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM(optional)
* | [--->] IV_DTEXT                       TYPE        STRING(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_icon.
    DATA ls_ricon TYPE ty_icon.
    CHECK icon_exists( iv_icon ) = abap_false.
    ls_ricon-icon = iv_icon.
    ls_ricon-function = iv_function.
    CREATE OBJECT ls_ricon-iconobj
      EXPORTING
        iv_qinfo_text = iv_qinfo_text
        iv_function   = iv_function
        iv_dtext      = iv_dtext
        iv_icon       = iv_icon.

    INSERT ls_ricon INTO TABLE mt_data.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_ALV                         TYPE REF TO lcl_ALV_BASE(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    mo_alv = io_alv.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->FILL_ICON_SUB_TAB
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_SUB                         TYPE        TY_ICON_SUB_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD fill_icon_sub_tab.
    FIELD-SYMBOLS <icon>   TYPE ty_icon.
    DATA ls_sub TYPE  ty_icon_sub.
    LOOP AT mt_data ASSIGNING <icon>.
      ls_sub-icon_d = <icon>-icon.
      ls_sub-icon_q = <icon>-iconobj->mv_enc_icon.
      INSERT ls_sub INTO TABLE ct_sub.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->FUNCTION_EXISTS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* | [<-()] RETVAL                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD function_exists.
    READ TABLE mt_data TRANSPORTING NO FIELDS
      WITH KEY function_key COMPONENTS function = iv_function.
    IF sy-subrc = 0.
      retval = abap_true.
    ELSE.
      retval = abap_false.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->GET_FUNCTION_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM
* | [<-()] RETVAL                         TYPE REF TO lcl_ALV_ICON
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_function_icon.

    FIELD-SYMBOLS: <ricon> TYPE ty_icon.
    READ TABLE mt_data ASSIGNING <ricon>
      WITH  KEY function_key COMPONENTS function = iv_function.
    IF sy-subrc = 0.
      retval = <ricon>-iconobj.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->GET_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [<-()] RETVAL                         TYPE REF TO lcl_ALV_ICON
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_icon.

    FIELD-SYMBOLS: <ricon> TYPE ty_icon.
    READ TABLE mt_data ASSIGNING <ricon>
      WITH TABLE KEY icon = iv_icon.
    IF sy-subrc = 0.
      retval = <ricon>-iconobj.
    ENDIF.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->HAS_ICONS
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD has_icons.
    IF lines( mt_data ) > 0.
      retval = abap_true.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICONS->ICON_EXISTS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [<-()] RETVAL                         TYPE        ICON_D
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD icon_exists.
    READ TABLE mt_data TRANSPORTING NO FIELDS
      WITH KEY icon = iv_icon.
    IF sy-subrc = 0.
      retval = abap_true.
    ELSE.
      retval = abap_false.
    ENDIF.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_alv_icon IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICON->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [--->] IV_QINFO_TEXT                  TYPE        STRING(optional)
* | [--->] IV_FUNCTION                    TYPE        SYUCOMM(optional)
* | [--->] IV_DTEXT                       TYPE        STRING(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    mv_icon = iv_icon.
    mv_qtext = iv_qinfo_text.
    mv_dtext = iv_dtext.
    mv_function = iv_function.
    mv_enc_icon = encode_icon( iv_icon = iv_icon iv_qinfo_text = iv_qinfo_text ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_ALV_ICON->CREATE_BUTTON
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        STB_BUTTON
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD create_button.
    retval-function = mv_function.
    retval-icon = mv_icon.
    retval-quickinfo = mv_qtext.
    retval-text = mv_dtext.
    retval-butn_type = 0.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_ALV_ICON=>ENCODE_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [--->] IV_QINFO_TEXT                  TYPE        STRING
* | [<-()] RETVAL                         TYPE        CHAR80
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD encode_icon.
    retval = |{ iv_icon+0(3) }\\Q{ iv_qinfo_text }@|.

  ENDMETHOD.
ENDCLASS.




CLASS lcl_alv_fcat IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_fcat->APPLY_PROPERTIES
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD apply_properties.
    DATA lv_chg_cnt TYPE i.
    FIELD-SYMBOLS <fcat> TYPE lvc_s_fcat.
    FIELD-SYMBOLS <ffld> TYPE any.
    FIELD-SYMBOLS <prop> TYPE ty_fcat_prop.
    mo_alv->get_frontend_fieldcatalog( IMPORTING et_fieldcatalog = mt_fcat ).
    SORT mt_fcat_prop BY fieldname seq.
    LOOP AT mt_fcat_prop ASSIGNING <prop>.
      IF <fcat> IS NOT ASSIGNED
      OR <fcat>-fieldname <> <prop>-fieldname.
        READ TABLE mt_fcat WITH KEY fieldname = <prop>-fieldname ASSIGNING <fcat>.
        CHECK sy-subrc = 0.
      ENDIF.
      ASSIGN COMPONENT <prop>-propname OF STRUCTURE <fcat> TO <ffld>.
      IF <ffld> IS ASSIGNED.
        <ffld> = <prop>-propvalue.
        lv_chg_cnt = lv_chg_cnt + 1.
      ENDIF.
    ENDLOOP.
    IF lv_chg_cnt > 0.
      mo_alv->set_frontend_fieldcatalog( mt_fcat ).
    ENDIF.
    REFRESH mt_fcat_prop[].
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_fcat->BUILD_FCAT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_AUTO                        TYPE        ABAP_BOOL (default ='X')
* | [--->] IV_MIN                         TYPE        ABAP_BOOL(optional)
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD build_fcat.
    FIELD-SYMBOLS <comp> TYPE abap_componentdescr.
    FIELD-SYMBOLS <fcat> TYPE lvc_s_fcat.
    DATA lo_compd TYPE REF TO cl_abap_datadescr.
    DATA lv_nam TYPE dd02l-tabname.
    lv_nam = mv_ddic_name.
    IF iv_auto = abap_true.
      IF mv_ddic_avail = abap_true.
        CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
          EXPORTING
            i_structure_name       = lv_nam
          CHANGING
            ct_fieldcat            = mt_fcat
          EXCEPTIONS
            inconsistent_interface = 1
            program_error          = 2.
      ENDIF.
      IF sy-subrc <> 0.
        REFRESH mt_fcat[].
      ENDIF.
    ENDIF.
    IF lines( mt_fcat ) = 0.
      LOOP AT mt_comp ASSIGNING <comp>.
        APPEND INITIAL LINE TO mt_fcat ASSIGNING <fcat>.
        <fcat>-fieldname = <comp>-name.
        lo_compd = <comp>-type.
        <fcat>-inttype = lo_compd->type_kind.
        <fcat>-outputlen = lo_compd->length.
        <fcat>-coltext = <comp>-name.
        <fcat>-seltext = <comp>-name.
      ENDLOOP.

    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_fcat->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IO_ALV                         TYPE REF TO lcl_alv_base(optional)
* | [--->] IO_SDESC                       TYPE REF TO CL_ABAP_STRUCTDESCR
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    mo_alv = io_alv.
    mo_sdesc = io_sdesc.
    mt_comp = mo_sdesc->get_components( ).
    mv_ddic_name = mo_sdesc->get_relative_name( ).
    mo_sdesc->get_ddic_field_list(
      RECEIVING
        p_field_list = mt_ddic
      EXCEPTIONS
        not_found = 1
        no_ddic_type = 2
        OTHERS = 3 ).
    IF sy-subrc = 0.
      mv_ddic_avail = abap_true.
    ENDIF.
    build_fcat(  ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>CREATE_BY_DATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_DATA                        TYPE        ANY
* | [--->] IO_ALV                         TYPE REF TO lcl_alv_base(optional)
* | [<-()] RETVAL                         TYPE REF TO lcl_alv_fcat
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD create_by_data.
    DATA lo_desc TYPE REF TO cl_abap_typedescr.
    DATA lo_tdesc        TYPE REF TO cl_abap_tabledescr.
    DATA lo_sdesc        TYPE REF TO cl_abap_structdescr.
    DATA lv_str TYPE string.
    lo_desc = cl_abap_typedescr=>describe_by_data( is_data ).
    lv_str = cl_abap_typedescr=>describe_by_object_ref( lo_desc )->get_relative_name( ).
    CHECK lv_str = c_stru  OR lv_str = c_tabl.
    IF lv_str = c_tabl.
      lo_tdesc ?= lo_desc.
      lo_sdesc ?= lo_tdesc->get_table_line_type( ).
    ELSE.
      lo_sdesc ?= lo_desc.
    ENDIF.
    CREATE OBJECT retval EXPORTING io_sdesc = lo_sdesc io_alv = io_alv.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>CREATE_BY_NAME
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_NAME                        TYPE        STRING
* | [--->] IO_ALV                         TYPE REF TO lcl_alv_base(optional)
* | [<-()] RETVAL                         TYPE REF TO lcl_alv_fcat
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD create_by_name.
    DATA lo_desc TYPE REF TO cl_abap_typedescr.
    DATA lo_sdesc TYPE REF TO cl_abap_structdescr.
    DATA lv_str TYPE string.
    lo_desc = cl_abap_typedescr=>describe_by_name( iv_name ).
    lv_str = cl_abap_typedescr=>describe_by_object_ref( lo_desc )->get_relative_name( ).
    CHECK lv_str = c_stru.
    lo_sdesc ?= lo_desc.
    CREATE OBJECT retval EXPORTING io_sdesc = lo_sdesc io_alv = io_alv.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>GET_COLHEADS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_NAME                        TYPE        STRING
* | [--->] IV_HEAD_TYPE                   TYPE        STRING(optional)
* | [<-()] RETVAL                         TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_colheads.
    DATA lt_flds TYPE ddfields.

    FIELD-SYMBOLS <txt> TYPE any.
    FIELD-SYMBOLS <fld> TYPE dfies.
*    lt_flds = get_named_DEFN( iv_name ).
    LOOP AT lt_flds ASSIGNING <fld>.
      IF strlen( retval ) > 0.
        retval = retval && '|'.
      ENDIF.
      retval = retval && <fld>-fieldname.
      CASE iv_head_type.
        WHEN 'S'.
          ASSIGN <fld>-scrtext_s TO <txt>.
        WHEN 'M'.
          ASSIGN <fld>-scrtext_m TO <txt>.
        WHEN 'L'.
          ASSIGN <fld>-scrtext_l TO <txt>.
        WHEN 'R'.
          ASSIGN <fld>-reptext TO <txt>.
        WHEN OTHERS.
          ASSIGN <fld>-scrtext_m TO <txt>.
      ENDCASE.
      IF strlen( <txt> ) <> 0.
        retval = retval && ',' && <txt>.
      ELSE.
        retval = retval && <fld>-fieldname.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>GET_STRUCT_COMP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_DATA                        TYPE        ANY
* | [<-()] RETVAL                         TYPE        ABAP_COMPONENT_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_struct_comp.
    DATA lo_sdesc        TYPE REF TO cl_abap_structdescr.
    lo_sdesc ?= cl_abap_typedescr=>describe_by_data( is_data ).
    retval   = lo_sdesc->get_components( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>GET_STRUCT_FLDS
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_DATA                        TYPE        ANY
* | [<-()] RETVAL                         TYPE        DDFIELDS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_struct_flds.
    DATA lo_sdesc        TYPE REF TO cl_abap_structdescr.
    lo_sdesc ?= cl_abap_typedescr=>describe_by_data( is_data ).
    retval = lo_sdesc->get_ddic_field_list(  ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>GET_TABLE_COMP
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_DATA                        TYPE        STANDARD TABLE
* | [<-()] RETVAL                         TYPE        ABAP_COMPONENT_TAB
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_table_comp.
    DATA lo_sdesc        TYPE REF TO cl_abap_structdescr.
    DATA lo_tdesc        TYPE REF TO cl_abap_tabledescr.

    lo_tdesc ?= cl_abap_typedescr=>describe_by_data( it_data ).
    lo_sdesc ?= lo_tdesc->get_table_line_type( ).
    retval   = lo_sdesc->get_components( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_fcat=>GET_TABLE_DEFN
* +-------------------------------------------------------------------------------------------------+
* | [--->] IT_DATA                        TYPE        STANDARD TABLE
* | [<-()] RETVAL                         TYPE        DDFIELDS
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_table_defn.
    DATA lo_sdesc        TYPE REF TO cl_abap_structdescr.
    DATA lo_tdesc        TYPE REF TO cl_abap_tabledescr.

    lo_tdesc ?= cl_abap_typedescr=>describe_by_data( it_data ).
    lo_sdesc ?= lo_tdesc->get_table_line_type( ).
    retval = lo_sdesc->get_ddic_field_list( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_fcat->IS_FCAT_DIRTY
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD is_fcat_dirty.
    IF lines( mt_fcat_prop ) > 0.
      retval = abap_true.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_fcat->SET_PROPERTY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FIELDNAME                   TYPE        STRING
* | [--->] IV_PROPNAME                    TYPE        STRING
* | [--->] IV_PROPVALUE                   TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_property.
    FIELD-SYMBOLS <prop> TYPE ty_fcat_prop.
    APPEND INITIAL LINE TO mt_fcat_prop ASSIGNING <prop>.
    <prop>-seq = lines( mt_fcat_prop ).
    <prop>-fieldname = iv_fieldname.
    <prop>-propname = iv_propname.
    <prop>-propvalue = iv_propvalue.
  ENDMETHOD.
ENDCLASS.



CLASS lcl_alv_base IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ADD_F4_HELP_ITEM
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FIELDNAME                   TYPE        LVC_FNAME
* | [--->] IV_GETBEFORE                   TYPE        LVC_COMPL(optional)
* | [--->] IV_CHNGEAFTER                  TYPE        LVC_COMPL(optional)
* | [--->] IV_INTERNAL                    TYPE        LVC_INTER(optional)
* | [--->] IV_REGISTER                    TYPE        LVC_REGIS (default ='X')
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_f4_help_item.
    DATA:: ls_f4 TYPE lvc_s_f4.
    ls_f4-fieldname  = iv_fieldname .
    ls_f4-register   = iv_register  .
    ls_f4-getbefore  = iv_getbefore .
    ls_f4-chngeafter = iv_chngeafter.
    ls_f4-internal   = iv_internal  .
    INSERT ls_f4 INTO TABLE mt_f4_help.
    register_f4_for_fields( mt_f4_help ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ADD_SORT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FIELDNAME                   TYPE        STRING
* | [--->] IV_SORT                        TYPE        ANY (default ='A')
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD add_sort.

**********************************************************************************
*Description: Add a sort sequence for initialization
**********************************************************************************
    DATA lv_seq TYPE i.

    APPEND INITIAL LINE TO gt_sort ASSIGNING FIELD-SYMBOL(<sort>).
    <sort>-fieldname = iv_fieldname.
    IF iv_sort = 'D'.
      <sort>-down = 'X'.
    ELSE.
      <sort>-up = 'X'.
    ENDIF.
    <sort>-level = lines( gt_sort ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->CONSTRUCTOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] I_DATA                         TYPE        ANY
* | [--->] IV_DYNNR                       TYPE        SY-DYNNR(optional)
* | [--->] IO_PARENT                      TYPE REF TO CL_GUI_CONTAINER(optional)
* | [--->] IV_LIFETIME                    TYPE        I(optional)
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD constructor.
    DATA lo_parent TYPE REF TO cl_gui_container.
    DATA lo_dock TYPE REF TO cl_gui_docking_container.
    IF offline( ) IS INITIAL.  "Foreground Model
      IF io_parent IS NOT SUPPLIED
      AND iv_dynnr IS NOT SUPPLIED.
        RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>setup_error.
      ENDIF.
      IF io_parent IS SUPPLIED
      AND iv_dynnr IS SUPPLIED.
        RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>setup_error.
      ENDIF.
      IF iv_dynnr IS SUPPLIED.
        CREATE OBJECT lo_dock
          EXPORTING
            lifetime = iv_lifetime
            ratio    = 95
            dynnr    = iv_dynnr.
        lo_parent = lo_dock.
      ELSE.
        lo_parent = io_parent.
      ENDIF.
    ELSE.
      lo_parent ?= lo_dock.
    ENDIF.
    super->constructor(
     EXPORTING
        i_lifetime = iv_lifetime
        i_parent = lo_parent ).
    mo_fcat = lcl_alv_fcat=>create_by_data( EXPORTING is_data = i_data io_alv = me ).
    CREATE OBJECT mo_tbar EXPORTING io_alv = me.
    CREATE OBJECT mo_icons.
    mo_tbar->mo_icons = mo_icons.
    default_layout( ).
    SET HANDLER on_toolbar FOR me      .
    SET HANDLER on_user_command FOR me      .
    SET HANDLER on_menu_button FOR me.
    SET HANDLER on_top_of_page FOR me.
    mv_default_toolbar = '&DETAIL,&&SEP00,&SORT_ASC,&SORT_DSC,&FIND,&FIND_MORE,&MB_FILTER,&&SEP05,&PRINT_BACK,&MB_VIEW,&MB_EXPORT,&COL0,&MB_VARIANT'.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Protected Method lcl_alv_base->DEFAULT_LAYOUT
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD default_layout.
    ms_layo = get_layout( ).
    ms_layo-smalltitle = 'X'.      "The list title has small fonts,
    ms_layo-no_toolbar = ' '.      "the toolbar is suppressed.
    ms_layo-no_rowmark = ' '.
    ms_layo-sel_mode = 'A'.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->DISPLAY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IS_VARIANT                     TYPE        DISVARIANT(optional)
* | [--->] IV_SAVE                        TYPE        CHAR01(optional)
* | [--->] IV_DEFAULT                     TYPE        CHAR01 (default ='X')
* | [--->] IS_LAYOUT                      TYPE        LVC_S_LAYO(optional)
* | [<-->] CT_DATA                        TYPE        STANDARD TABLE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD display.

    DATA lt_icon TYPE lcl_alv_icons=>ty_icon_sub_tab.
    FIELD-SYMBOLS <fcat> TYPE lvc_s_fcat.
    FIELD-SYMBOLS <icon> TYPE lcl_alv_icons=>ty_icon_sub.
    FIELD-SYMBOLS <cell> TYPE any.
    FIELD-SYMBOLS <rowdata> TYPE any.
    IF mv_first_display = abap_true.
      RAISE EVENT custom_setup.
      set_frontend_fieldcatalog( EXPORTING it_fieldcatalog = mo_fcat->mt_fcat ).
      mo_fcat->apply_properties( ).
      set_table_for_first_display(
        EXPORTING
           is_layout = ms_layo
           is_variant = is_variant
           i_save    =  iv_save
           i_default =  iv_default
        CHANGING
           it_fieldcatalog = mo_fcat->mt_fcat
           it_sort         = gt_sort
           it_outtab = ct_data ).
    ENDIF.

    IF mo_tbar->mv_dirty = abap_true.
      me->set_toolbar_interactive( ).
    ENDIF.

    IF mo_icons->has_icons( ) = abap_true.
      mo_icons->fill_icon_sub_tab( CHANGING ct_sub = lt_icon ).
      LOOP AT mo_fcat->mt_fcat ASSIGNING <fcat>.
        CHECK <fcat>-icon = 'X'.
        LOOP AT ct_data ASSIGNING <rowdata>.             "#EC CI_NESTED
          ASSIGN COMPONENT <fcat>-fieldname OF STRUCTURE <rowdata> TO <cell>.
          IF <cell> IS NOT INITIAL.
            READ TABLE lt_icon ASSIGNING <icon> WITH TABLE KEY icon_d = <cell>.
            IF sy-subrc = 0.
              <cell> = <icon>-icon_q.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDLOOP.
    ENDIF.
    IF mo_fcat->is_fcat_dirty( ) = abap_true.
      mo_fcat->apply_properties( ).
      refresh_table_display( EXPORTING i_soft_refresh = ' ' ).
    ELSE.
      IF mv_first_display IS INITIAL.
        refresh_table_display( ).
      ENDIF.
    ENDIF.
    CLEAR mv_first_display.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ACTIVE_CELLDATA
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE REF TO DATA
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_active_celldata.
    FIELD-SYMBOLS <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS <dat> TYPE any.
    FIELD-SYMBOLS <fld> TYPE any.
    DATA: lv_row TYPE i.
    DATA: lv_nam TYPE string.
    TRY.
        lv_nam = get_active_cellid( ).
        lv_row = get_active_row( ).
        ASSIGN mt_outtab->* TO <tab>.
        READ TABLE <tab> INDEX lv_row ASSIGNING <dat>.
        CHECK sy-subrc = 0.
        ASSIGN COMPONENT lv_nam OF STRUCTURE <dat> TO <fld>.
        GET REFERENCE OF <fld> INTO retval.
      CATCH zcx_cop_alv_exception.
    ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ACTIVE_CELLID
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_active_cellid.
    DATA lv_col TYPE i.
    DATA lt_colpos TYPE lvc_t_coll.
    FIELD-SYMBOLS: <col> TYPE lvc_s_coll.
    TRY.
        lv_col =  me->get_active_col( ).
        get_col_pos_id_base( IMPORTING col_pos_table = lt_colpos ).
        READ TABLE lt_colpos ASSIGNING <col> INDEX lv_col.
        CHECK sy-subrc = 0.
        retval = <col>-col_id.
      CATCH zcx_cop_alv_exception.
    ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ACTIVE_COL
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        I
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_active_col.

    get_current_cell_col( IMPORTING col = retval ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ACTIVE_ROW
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        I
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_active_row.

    get_current_cell_row( IMPORTING row = retval ).
    cl_gui_cfw=>flush( ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ACTIVE_ROWDATA
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CS_DATA                        TYPE        ANY
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_active_rowdata.
    DATA: lv_row TYPE i.
    lv_row = get_active_row( ).
    get_rowdata( EXPORTING iv_row = lv_row CHANGING cs_data = cs_data ).
    cl_gui_cfw=>flush( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method lcl_alv_base=>GET_ALV_COLOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_COLOR                       TYPE        NUM1
* | [--->] IV_INTENSITY                   TYPE        ANY (default ='1')
* | [--->] IV_INVERSE                     TYPE        ANY (default ='0')
* | [<-()] RETVAL                         TYPE        CHAR4
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_alv_color.
**********************************************************************************
    "                             *****  Mod Log   *****                             *
    "23.10.2017 15:50:31  PRIESJC
    " Description:  bUILD A COLOR FOR THE ALV ROW
**********************************************************************************
    retval = |C{ iv_color }{ iv_intensity }{ iv_inverse }|.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_DEFAULT_TOOLBAR
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_default_toolbar.
    retval = mv_default_toolbar.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_FIRST_SELECTED_ROW
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        I
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_first_selected_row.

    DATA: lr_rid TYPE REF TO lvc_t_roid.
    FIELD-SYMBOLS <rid> TYPE lvc_s_roid.
    IF get_selected_row_count( ) <= 0.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>rows_not_selected.
    ENDIF.
    lr_rid = get_selected_rowsv( ).
    READ TABLE lr_rid->* INDEX 1 ASSIGNING <rid>.
    retval = <rid>-row_id.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_FIRST_SELECTED_ROWDATA
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CS_DATA                        TYPE        ANY
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_first_selected_rowdata.
    DATA: lv_ndx TYPE i.
    IF get_selected_row_count( ) <= 0.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>rows_not_selected.
    ENDIF.
    lv_ndx = get_first_selected_row( ).
    get_rowdata( EXPORTING iv_row = lv_ndx CHANGING cs_data = cs_data ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_HEADER_HTML
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_header_html.
    retval = mv_html_hdr.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_LAYOUT
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        LVC_S_LAYO
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_layout.
    get_frontend_layout( IMPORTING es_layout = retval ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_OKCODE
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        SYUCOMM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_okcode.
    retval = mv_okcode.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_ROWDATA
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ROW                         TYPE        I
* | [<-->] CS_DATA                        TYPE        ANY
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_rowdata.

    FIELD-SYMBOLS: <tab> TYPE STANDARD TABLE.
    IF is_row_valid( iv_row ) = abap_false.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>row_does_not_exist.
    ENDIF.

    ASSIGN mt_outtab->* TO <tab>.
    READ TABLE <tab> INDEX iv_row INTO cs_data.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_SELECTED_DATA
* +-------------------------------------------------------------------------------------------------+
* | [<-->] CT_TABLE                       TYPE        STANDARD TABLE
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_selected_data.

    DATA: lr_roid TYPE REF TO lvc_t_roid.
    FIELD-SYMBOLS: <tab> TYPE STANDARD TABLE.
    FIELD-SYMBOLS: <roid> TYPE lvc_s_roid.
    IF get_selected_row_count( ) <= 0.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>rows_not_selected.
    ENDIF.
    lr_roid = get_selected_rowsv( ).
    ASSIGN mt_outtab->* TO <tab>.
    LOOP AT lr_roid->* ASSIGNING <roid>.
      APPEND LINES OF <tab> FROM <roid>-row_id TO <roid>-row_id TO ct_table.
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_SELECTED_ROWSV
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE REF TO LVC_T_ROID
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_selected_rowsv.
*    IF get_selected_row_count( ) <= 0.
*      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>rows_not_selected.
*    ENDIF.
    CREATE DATA retval.
    get_selected_rows( IMPORTING et_row_no = retval->* ).
    IF lines( retval->* ) < 1.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>rows_not_selected.
    ENDIF.


  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->GET_SELECTED_ROW_COUNT
* +-------------------------------------------------------------------------------------------------+
* | [<-()] RETVAL                         TYPE        I
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD get_selected_row_count.
    DATA: lr_roid TYPE REF TO lvc_t_roid.
    TRY.
        lr_roid = get_selected_rowsv( ).
        retval = lines( lr_roid->* ).
      CATCH zcx_cop_alv_exception.
        retval = 0.
    ENDTRY.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->IS_ROW_SELECTED
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ROW                         TYPE        I
* | [<-()] RETVAL                         TYPE        I
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD is_row_selected.
    DATA: lr_sel TYPE REF TO lvc_t_roid.
    IF is_row_valid(  iv_row ) = abap_false.
      RAISE EXCEPTION TYPE zcx_cop_alv_exception EXPORTING textid = zcx_cop_alv_exception=>row_does_not_exist.
    ENDIF.
    lr_sel = get_selected_rowsv( ).
    READ TABLE lr_sel->* TRANSPORTING NO FIELDS WITH KEY row_id = iv_row.
    IF sy-subrc = 0.
      retval = abap_true.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->IS_ROW_VALID
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ROW                         TYPE        I
* | [<-()] RETVAL                         TYPE        ABAP_BOOL
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD is_row_valid.
    FIELD-SYMBOLS: <tab> TYPE STANDARD TABLE.
    ASSIGN mt_outtab->* TO <tab>.
    IF  <tab> IS ASSIGNED
    AND iv_row > 0
    AND iv_row <= lines( <tab> ).
      retval = abap_true.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_AFTER_REFRESH
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_after_refresh.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_AFTER_USER_COMMAND
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_UCOMM                        LIKE
* | [--->] E_SAVED                        LIKE
* | [--->] E_NOT_PROCESSED                LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_after_user_command.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_BEFORE_USER_COMMAND
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_UCOMM                        LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_before_user_command.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_BUTTON_CLICK
* +-------------------------------------------------------------------------------------------------+
* | [--->] ES_COL_ID                      LIKE
* | [--->] ES_ROW_NO                      LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_button_click.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_CELL_CHANGED
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_cell_changed.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_CONTEXT_MENU_REQUEST
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_OBJECT                       LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_context_menu_request.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DATA_CHANGED
* +-------------------------------------------------------------------------------------------------+
* | [--->] ER_DATA_CHANGED                LIKE
* | [--->] E_ONF4                         LIKE
* | [--->] E_ONF4_BEFORE                  LIKE
* | [--->] E_ONF4_AFTER                   LIKE
* | [--->] E_UCOMM                        LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_data_changed.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DATA_CHANGED_FINISHED
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_MODIFIED                     LIKE
* | [--->] ET_GOOD_CELLS                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_data_changed_finished.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DELAYED_CELL
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_delayed_cell.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DELAYED_SEL
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_delayed_sel.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DOUBLE_CLICK
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW                          LIKE
* | [--->] E_COLUMN                       LIKE
* | [--->] ES_ROW_NO                      LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_double_click.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_DROP_EXTERNAL_FILES
* +-------------------------------------------------------------------------------------------------+
* | [--->] FILES                          LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_drop_external_files.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_END_OF_LIST
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_DYNDOC_ID                    LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_end_of_list.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_HOTSPOT_CLICK
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW_ID                       LIKE
* | [--->] E_COLUMN_ID                    LIKE
* | [--->] ES_ROW_NO                      LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_hotspot_click.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_MENU_BUTTON
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_OBJECT                       LIKE
* | [--->] E_UCOMM                        LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_menu_button.
    me->mo_tbar->build_menu( EXPORTING iv_ucomm = e_ucomm io_menu = e_object ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONDRAG
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW                          LIKE
* | [--->] E_COLUMN                       LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] E_DRAGDROPOBJ                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_ondrag.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONDROP
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW                          LIKE
* | [--->] E_COLUMN                       LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] E_DRAGDROPOBJ                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_ondrop.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONDROPCOMPLETE
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW                          LIKE
* | [--->] E_COLUMN                       LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] E_DRAGDROPOBJ                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_ondropcomplete.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONDROPGETFLAVOR
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_ROW                          LIKE
* | [--->] E_COLUMN                       LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] E_DRAGDROPOBJ                  LIKE
* | [--->] E_FLAVORS                      LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_ondropgetflavor.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONF1
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_FIELDNAME                    LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] ER_EVENT_DATA                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_onf1.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_ONF4
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_FIELDNAME                    LIKE
* | [--->] E_FIELDVALUE                   LIKE
* | [--->] ES_ROW_NO                      LIKE
* | [--->] ER_EVENT_DATA                  LIKE
* | [--->] ET_BAD_CELLS                   LIKE
* | [--->] E_DISPLAY                      LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_onf4.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_PRINT_END_OF_LIST
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_print_end_of_list.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_PRINT_END_OF_PAGE
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_print_end_of_page.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_PRINT_TOP_OF_LIST
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_print_top_of_list.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_PRINT_TOP_OF_PAGE
* +-------------------------------------------------------------------------------------------------+
* | [--->] TABLE_INDEX                    LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_print_top_of_page.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_SELECTION_CHANGED
* +-------------------------------------------------------------------------------------------------+
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_selection_changed.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_SUBTOTAL_TEXT
* +-------------------------------------------------------------------------------------------------+
* | [--->] ES_SUBTOTTXT_INFO              LIKE
* | [--->] EP_SUBTOT_LINE                 LIKE
* | [--->] E_EVENT_DATA                   LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_subtotal_text.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_TOOLBAR
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_OBJECT                       LIKE
* | [--->] E_INTERACTIVE                  LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_toolbar.
    mo_tbar->merge_tools( CHANGING ct_tbar = e_object->mt_toolbar ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_TOP_OF_PAGE
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_DYNDOC_ID                    LIKE
* | [--->] TABLE_INDEX                    LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_top_of_page.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->ON_USER_COMMAND
* +-------------------------------------------------------------------------------------------------+
* | [--->] E_UCOMM                        LIKE
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD on_user_command.
    FIELD-SYMBOLS <but> TYPE lcl_alv_tbar=>ty_but.
    mv_okcode = e_ucomm.
    READ TABLE mo_tbar->mt_but ASSIGNING <but>
      WITH KEY function = mv_okcode.
    IF sy-subrc = 0.
      IF <but>-passthru = abap_true.
        push_to_sapgui( mv_okcode ).
      ENDIF.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->PUSH_TO_SAPGUI
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FUNCTION                    TYPE        SY-UCOMM
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD push_to_sapgui.
    DATA lv_rc TYPE i.
    " Method set_new_OK_CODE does not appear to be working correctly.
    " OK code is not being recieved nor is SY-ucomm being set.
    CALL METHOD cl_gui_cfw=>set_new_ok_code
      EXPORTING
        new_code = iv_function
      IMPORTING
        rc       = lv_rc.
*    cl_gui_cfw=>set_new_ok_code( EXPORTING new_code = iv_function IMPORTING rc = lv_rc ).
    cl_gui_cfw=>flush( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->QINFO_ADD_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [--->] IV_QINFO_TEXT                  TYPE        CHAR50
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD qinfo_add_icon.
    DATA lv_str TYPE string.
    lv_str = iv_qinfo_text.
    mo_icons->add_icon( iv_icon = iv_icon iv_qinfo_text = lv_str ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->QINFO_GET_ICON
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [<-()] RETVAL                         TYPE        CHAR80
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD qinfo_get_icon.
    DATA lo_ico TYPE REF TO lcl_alv_icon.
    lo_ico = qinfo_get_icon_obj( iv_icon ).
    IF lo_ico IS BOUND.
      retval = lo_ico->mv_enc_icon.
    ELSE.
      retval = iv_icon.
    ENDIF.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->QINFO_GET_ICON_OBJ
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ICON                        TYPE        ICON_D
* | [<-()] RETVAL                         TYPE REF TO lcl_ALV_ICON
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD qinfo_get_icon_obj.
    retval = mo_icons->get_icon( iv_icon ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_ACTIVE_CELL
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ROW                         TYPE        I
* | [--->] IV_COLNAME                     TYPE        STRING
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_active_cell.

    DATA: ls_row TYPE lvc_s_row,
          ls_col TYPE lvc_s_col.
    ls_row-index = iv_row.
    ls_col-fieldname = iv_colname.
    set_current_cell_via_id( is_row_id = ls_row
        is_column_id = ls_col ).
    select_text_in_curr_cell( ).
    cl_gui_cfw=>flush( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_ACTIVE_ROW
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_ROW                         TYPE        I
* | [!CX!] ZCX_COP_ALV_EXCEPTION
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_active_row.
    DATA ls_row     TYPE lvc_s_row.
    ls_row-index = iv_row.
    set_current_cell_via_id( is_row_id = ls_row ).
    select_text_in_curr_cell( ).
    cl_gui_cfw=>flush( ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_DEFAULT_TOOLBAR
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_TOOLBAR                     TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_default_toolbar.
    mv_default_toolbar = iv_toolbar.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_DELAY_CELL_CHG
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_DELAY                       TYPE        I
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_delay_cell_chg.
    me->set_delay_move_current_cell( iv_delay ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_DELAY_SELECTION
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_DELAY                       TYPE        I
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_delay_selection.
    me->set_delay_change_selection( iv_delay ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_FCAT
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FIELDNAME                   TYPE        STRING
* | [--->] IV_PROPNAME                    TYPE        STRING
* | [--->] IV_PROPVALUE                   TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_fcat.
    mo_fcat->set_property( EXPORTING iv_fieldname = iv_fieldname iv_propname = iv_propname iv_propvalue = iv_propvalue ).
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_FCAT_MANY
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_FIELDNAME                   TYPE        STRING
* | [--->] IV_PROPNAME                    TYPE        STRING
* | [--->] IV_PROPVALUE                   TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_fcat_many.
**********************************************************************************
    "                             *****  Mod Log   *****                             *
    "23.08.2017 13:20:48  PRIESJC  Set Many
    " Description:  Appends mulitple fields into the property list with the same values
**********************************************************************************
    DATA lt_nam TYPE STANDARD TABLE OF string.
    DATA lv_nam TYPE string.
    "Optionally you may submit multiple field names
    "Separated by the Pipe character '|' and assign
    "the same property and value to multiple columns.
    SPLIT iv_fieldname AT '|' INTO TABLE lt_nam.
    LOOP AT lt_nam INTO lv_nam.
      mo_fcat->set_property( EXPORTING iv_fieldname = lv_nam iv_propname = iv_propname iv_propvalue = iv_propvalue ).
    ENDLOOP.

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Instance Public Method lcl_alv_base->SET_HEADER_HTML
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_HTMLTEXT                    TYPE        STRING
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_header_html.
    mv_html_hdr = iv_htmltext.
    mv_html_hdr_dirty = abap_true.
  ENDMETHOD.
ENDCLASS.


CLASS lcl_dom2vrm IMPLEMENTATION.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method LCL_DOM2VRM=>DOM_2_VRM
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_VALUE                       TYPE        ANY
* | [<-()] RETVAL                         TYPE        VRM_VALUES
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD dom_2_vrm.

    DATA lo_tdesc TYPE REF TO cl_abap_typedescr.
    DATA lo_ddesc TYPE REF TO cl_abap_elemdescr.
    DATA lv_str TYPE string.
    " extract metadata of field
    lo_ddesc ?= cl_abap_datadescr=>describe_by_data( iv_value ).
* Read data dictionary to extract list of allowable values
    SELECT SINGLE domname FROM dd04l INTO @DATA(lv_dom) "#EC CI_NOORDER
      WHERE rollname = @lo_ddesc->help_id.
    CHECK sy-subrc = 0.
    " return value description list
    retval = elm_2_vrm( CONV #( lv_dom ) ).

  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method LCL_DOM2VRM=>ELM_2_VRM
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_NAME                        TYPE        STRING
* | [<-()] RETVAL                         TYPE        VRM_VALUES
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD elm_2_vrm.
**********************************************************************************
    "                             *****  Mod Log   *****                             *
    "10.10.2017 13:31:54  PRIESJC
    " Description: fIX VALUE RETURNED IN KEY

**********************************************************************************
    "  simple select domain value/text's into VRM Table
    "  and return vrm list
    SELECT domvalue_l, ddtext                            "#EC CI_BYPASS
      FROM dd07t
      INTO TABLE @DATA(lt_7t)
    WHERE ddlanguage = @sy-langu
      AND domname = @iv_name
      ORDER BY valpos.
    CHECK sy-subrc = 0.
    "Fill VRM LIST with Data Dictionary values
    LOOP AT lt_7t ASSIGNING FIELD-SYMBOL(<7t>).
      APPEND INITIAL LINE TO retval ASSIGNING FIELD-SYMBOL(<vrm>).
      <vrm>-key  = <7t>-domvalue_l.
      <vrm>-text = <7t>-ddtext.
    ENDLOOP.
  ENDMETHOD.


* <SIGNATURE>---------------------------------------------------------------------------------------+
* | Static Public Method LCL_DOM2VRM=>SET_VRM_LISTBOX
* +-------------------------------------------------------------------------------------------------+
* | [--->] IV_VALUE                       TYPE        ANY
* | [--->] IV_NAME                        TYPE        STRING
* | [<-()] RETVAL                         TYPE        SY-SUBRC
* +--------------------------------------------------------------------------------------</SIGNATURE>
  METHOD set_vrm_listbox.

    DATA ls_sd TYPE sydes_desc.
    DATA lv_id TYPE vrm_id.
    DATA lt_vrm TYPE vrm_values.

* Use variable to get list of values
    lt_vrm = dom_2_vrm( iv_value ).

* If there are no values exit
* otherwise fill the listbox of
* named field
    IF lines( lt_vrm ) = 0.
      retval = 3.
    ELSE.
      lv_id = iv_name.
      CALL FUNCTION 'VRM_SET_VALUES'
        EXPORTING
          id              = lv_id
          values          = lt_vrm
        EXCEPTIONS
          id_illegal_name = 1
          OTHERS          = 2.
      retval = sy-subrc.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

CLASS lcl_alv IMPLEMENTATION.


  METHOD re_display.

    DATA ls_variant  TYPE  disvariant.
    DATA lv_save     TYPE  char01.
    DATA lv_can_restore TYPE abap_bool.
    DATA lt_selsave TYPE ty_alvdata_tab.
    TRY.
        get_selected_data( CHANGING ct_table = lt_selsave ).
        lv_can_restore = abap_true.
      CATCH zcx_cop_alv_exception.
        CLEAR lv_can_restore.
    ENDTRY.
    " complete refresh
    ls_variant-report = sy-repid.
    refresh_data( ).
    ms_layo-grid_title = gv_grid_title.
    lv_save = 'U'.
    display( EXPORTING iv_save = lv_save is_variant = ls_variant CHANGING ct_data = gt_alvdata ).
    IF  iv_restore_sel = abap_true
    AND lv_can_restore  = abap_true.
      restore_selection( lt_selsave ).
    ENDIF.

  ENDMETHOD.

  METHOD display_log.

    DATA ls_alv TYPE ty_alvdata.

    TRY.
        get_active_rowdata( CHANGING cs_data = ls_alv ).

        IF ls_alv-trstatus = 'D'.
          gv_save_message = |{ ls_alv-strkorr } has not been released|.
        ELSE.
          SUBMIT rddprott AND RETURN WITH pv_korr  = ls_alv-strkorr. "#EC CI_SUBMIT
          gv_save_message = |Display of { ls_alv-strkorr } Complete|.
        ENDIF.
      CATCH zcx_cop_alv_exception.
        gv_save_message = 'Unable to display'.
    ENDTRY.
    re_display( abap_true ).

  ENDMETHOD.

  METHOD refresh_data.

    DATA lt_reqhdr  TYPE trwbo_request_headers.
    DATA ls_ranges  TYPE trsel_ts_ranges.
    DATA lt_users TYPE STANDARD TABLE OF sy-uname.
    DATA lt_dates TYPE STANDARD TABLE OF sy-datum.

    DATA lv_seq      TYPE i.
    DATA lv_tran_cnt TYPE i.
    DATA lv_partrfun TYPE trfunction.

    CLEAR gv_force_refresh.

    REFRESH gt_reqhdr[].
    REFRESH gt_alvdata[].

    " api call to sap for requests based on selection fields
    CALL FUNCTION 'TRINT_SELECT_REQUESTS'  "#EC CI_SUBRC
      IMPORTING
        et_requests            = gt_reqhdr
      CHANGING
        cs_ranges              = gs_ranges
      EXCEPTIONS
        action_aborted_by_user = 1
        OTHERS                 = 2.

    IF p_myopen = abap_true.
      APPEND INITIAL LINE TO ls_ranges-as4user ASSIGNING FIELD-SYMBOL(<user>).
      <user>-sign = 'I'.
      <user>-option = 'EQ'.
      <user>-low = sy-uname.

      APPEND INITIAL LINE TO ls_ranges-request_status ASSIGNING FIELD-SYMBOL(<sts>).
      <sts>-sign   = 'I'.
      <sts>-option = 'EQ'.
      <sts>-low    = 'D'.

      ls_ranges-trkorr[]  = gs_ranges-trkorr[].
      CALL FUNCTION 'TRINT_SELECT_REQUESTS'  "#EC CI_SUBRC
        IMPORTING
          et_requests            = lt_reqhdr
        CHANGING
          cs_ranges              = ls_ranges
        EXCEPTIONS
          action_aborted_by_user = 1
          OTHERS                 = 2.

      APPEND LINES OF lt_reqhdr TO gt_reqhdr.
    ENDIF.

    IF p_text IS NOT INITIAL.
      CLEAR ls_ranges.
      ls_ranges-as4text = p_text.
      ls_ranges-request_funcs = s_trfunc[].

      APPEND INITIAL LINE TO ls_ranges-as4user ASSIGNING <user>.
      <user>-sign = 'I'.
      <user>-option = 'EQ'.
      <user>-low = sy-uname.

      CALL FUNCTION 'TRINT_SELECT_REQUESTS'  "#EC CI_SUBRC
        IMPORTING
          et_requests            = lt_reqhdr
        CHANGING
          cs_ranges              = ls_ranges
        EXCEPTIONS
          action_aborted_by_user = 1
          OTHERS                 = 2.

      APPEND LINES OF lt_reqhdr TO gt_reqhdr.
    ENDIF.

    IF lines( gt_reqhdr ) = 0.
      EXIT.
    ENDIF.

    SORT gt_reqhdr.
    DELETE ADJACENT DUPLICATES FROM gt_reqhdr COMPARING trkorr.

    " Map function call results into internal table
    " first process all the Main Request headers
    " then pull all their children
    CLEAR gv_has_target.
    LOOP AT gt_reqhdr ASSIGNING FIELD-SYMBOL(<hdrg>) WHERE strkorr IS INITIAL.
      lv_tran_cnt = lv_tran_cnt + 1.
      lv_seq = 1.
      APPEND <hdrg>-as4date TO lt_dates. " Save date for Hi-Lo display
      APPEND <hdrg>-as4user TO lt_users. " Save users for user display
      APPEND INITIAL LINE TO gt_alvdata ASSIGNING FIELD-SYMBOL(<alv>).
      MOVE-CORRESPONDING <hdrg> TO <alv>.
      <alv>-strkorr = <alv>-trkorr.
      fill_tr_meta_data( CHANGING cs_alvdata = <alv> ).
      <alv>-sortseq = lv_seq.
      " if it has any Tasks append those
      LOOP AT gt_reqhdr ASSIGNING FIELD-SYMBOL(<hdr>) WHERE strkorr = <hdrg>-trkorr.
        APPEND <hdr>-as4date TO lt_dates.
        lv_seq = lv_seq + 1.
        APPEND INITIAL LINE TO gt_alvdata ASSIGNING <alv>.
        MOVE-CORRESPONDING <hdr> TO <alv>.
        <alv>-sortseq = lv_seq.
        <alv>-parent = <hdrg>.
        fill_tr_meta_data( CHANGING cs_alvdata = <alv> ).
      ENDLOOP.
    ENDLOOP.

    IF gv_has_target = abap_false.
      CLEAR gv_curr_target.
    ENDIF.

    SORT lt_dates.
    DELETE ADJACENT DUPLICATES FROM lt_dates.
    SORT lt_users.
    DELETE ADJACENT DUPLICATES FROM lt_users.

    DATA lv_dat_lo TYPE sy-datum.
    DATA lv_dat_hi TYPE sy-datum.
    DATA lv_text   TYPE string.

    READ TABLE lt_dates INDEX 1 INTO lv_dat_lo.
    lv_seq = lines( lt_dates ).
    READ TABLE lt_dates INDEX lv_seq INTO lv_dat_hi.

    LOOP AT lt_users ASSIGNING FIELD-SYMBOL(<usr>).
      IF strlen( lv_text ) = 0.
        lv_text = <usr>.
      ELSE.
        lv_text = |{ lv_text } / { <usr> }|.
      ENDIF.
    ENDLOOP.

    gv_grid_title = |Transports for { lv_text } from { lv_dat_lo DATE = USER } thru { lv_dat_hi DATE = USER }|.


  ENDMETHOD.


  METHOD fill_tr_meta_data.

    DATA lv_use_status   TYPE trstatus.
    DATA lv_use_function TYPE trfunction.

    " add descriptions from data dictionary VRM
    READ TABLE gt_func WITH KEY key = cs_alvdata-trfunction ASSIGNING FIELD-SYMBOL(<vrm>).
    IF sy-subrc = 0.
      cs_alvdata-trfunctiontext = |{ <vrm>-key }:{ <vrm>-text }|.
    ELSE.
      cs_alvdata-trfunctiontext = cs_alvdata-trfunction.
    ENDIF.
    READ TABLE gt_stat WITH KEY key = cs_alvdata-trstatus ASSIGNING <vrm>.
    IF sy-subrc = 0.
      cs_alvdata-trstatustext = |{ <vrm>-key }:{ <vrm>-text }|.
    ELSE.
      cs_alvdata-trstatustext = cs_alvdata-trstatus.
    ENDIF.

    IF cs_alvdata-parent IS INITIAL.
      cs_alvdata-trfunkey = cs_alvdata-trfunction && 'Z'.  "For maintaining sort sequence hidden field
      cs_alvdata-trstatkey = cs_alvdata-trstatus.          "For maintaining sort sequence hidden field
    ELSE.
      cs_alvdata-trfunkey = cs_alvdata-parent-trfunction && cs_alvdata-trfunction .
      cs_alvdata-trstatkey = cs_alvdata-parent-trstatus && cs_alvdata-trstatus .
    ENDIF.

    IF cs_alvdata-parent IS NOT INITIAL.
      lv_use_status = cs_alvdata-parent-trstatus.
    ELSE.
      lv_use_status = cs_alvdata-trstatus.
    ENDIF.
    IF cs_alvdata-parent IS NOT INITIAL.
      lv_use_function = cs_alvdata-parent-trfunction.
    ELSE.
      lv_use_function = cs_alvdata-trfunction.
    ENDIF.

    IF cs_alvdata-trkorr = gv_curr_target.
      cs_alvdata-groupkey+0(1) = '0'.
    ELSE.
      IF lv_use_status CA 'DL'.
        cs_alvdata-groupkey+0(1) = '1'.
      ELSE.
        cs_alvdata-groupkey+0(1) = '2'.
      ENDIF.
    ENDIF.

    IF lv_use_function = 'T'.
      cs_alvdata-groupkey+1(1) = '1'.
      cs_alvdata-row_color = get_alv_color( c_alv_color-blue ).
      cs_alvdata-row_icon = qinfo_get_icon( icon_ws_transport ).
    ELSE.
      cs_alvdata-row_icon = qinfo_get_icon( icon_routing ).
      cs_alvdata-row_color = get_alv_color( c_alv_color-gray ).
      cs_alvdata-groupkey+1(1) = '2'.
    ENDIF.

    IF cs_alvdata-parent IS NOT INITIAL.
      cs_alvdata-row_icon = qinfo_get_icon( icon_routing_sub_operation ).
      cs_alvdata-row_color+1(1) = '0'.
    ENDIF.

    "Set icons and row colors
    IF  cs_alvdata-trkorr = gv_curr_target.
      IF cs_alvdata-trstatus NA 'DL'.
      ELSE.
        gv_has_target = abap_true.
        cs_alvdata-row_icon  = qinfo_get_icon( icon_target_group ).
        cs_alvdata-row_color = get_alv_color( c_alv_color-yellow ).
      ENDIF.
    ENDIF.


    "Add child items, not really used
    cs_alvdata-children = go_alv->get_children( cs_alvdata-trkorr ).
    "Get child counts for display
    cs_alvdata-childcnt = lines( cs_alvdata-children-objects ).
    " clear out the children section until needed someday
    CLEAR cs_alvdata-children.



  ENDMETHOD.

  METHOD get_sel_state.

    DATA lt_alv TYPE ty_alvdata_tab.
    DATA lv_target TYPE trkorr.
    DATA lv_ndx TYPE i.

    retval-none = abap_true.

    "Ensure that active target wasn't deleted
    IF gv_curr_target IS NOT INITIAL.
      READ TABLE gt_alvdata TRANSPORTING NO FIELDS
        WITH KEY trkorr = gv_curr_target.
      IF sy-subrc <> 0.
        CLEAR gv_curr_target.
      ENDIF.
    ENDIF.

    " get the selected rows if it fails error will bubble up
    " exception handled by parent

    get_selected_data( CHANGING ct_table = lt_alv ).

    CLEAR retval-none.

    " save the number of lines
    retval-sel_cnt = lines( lt_alv ).

    READ TABLE lt_alv ASSIGNING FIELD-SYMBOL(<alv>) "Get first modifiable
      WITH KEY trfunction = 'T' "TOC
               trstatus = 'D'.  "Modifiable
    IF sy-subrc = 0.
      IF retval-sel_cnt = 1.
        retval-single_toc = <alv>-trkorr.
      ENDIF.
    ENDIF.

    DATA lv_found_cnt TYPE i.  "Count of modifiable TOC's selected

    IF iv_target IS NOT INITIAL.
      retval-target = iv_target.
      retval-new_target = abap_true.
    ELSE.
      IF gv_curr_target IS INITIAL.
        LOOP AT lt_alv ASSIGNING <alv>
           WHERE trfunction = 'T'  AND trstatus = 'D'. "TOC / Modifiable
          lv_found_cnt = lv_found_cnt + 1.
          IF lv_found_cnt > 1.
            CLEAR retval-target.
            EXIT.
          ENDIF.
          retval-target = <alv>-trkorr.
        ENDLOOP.
      ELSE.
        retval-target = gv_curr_target.
      ENDIF.
    ENDIF.

    " if target is not new figure out the first
    " modifiable TOC.
    " delete target from selected lines so it doesn't double it up
    " if new transport then none will be found
    DELETE lt_alv WHERE trkorr = retval-target.

    " get the counts.
    LOOP AT lt_alv  ASSIGNING <alv>.
      APPEND <alv>-trkorr TO retval-sources.
      IF  <alv>-trfunction = 'T'  "TOC
      AND <alv>-trstatus = 'D'  ." Modifiable
        retval-mod_toc_cnt = retval-mod_toc_cnt + 1.
      ENDIF.

      retval-src_cnt = retval-src_cnt + 1.
      retval-src_obj_cnt = retval-src_obj_cnt + <alv>-childcnt.
      IF  retval-src_text IS INITIAL.
        retval-src_text = <alv>-trkorr.
      ELSE.
        retval-src_text = |{ retval-src_text }, { <alv>-trkorr }|.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.

  METHOD restore_selection.
* if the data is refreshed try to restore selections
    DATA lt_sel  TYPE lvc_t_row.
    DATA lv_ndx  TYPE i.
    IF lines( it_alvdata ) > 0.
      LOOP AT it_alvdata ASSIGNING FIELD-SYMBOL(<alv>).
        READ TABLE gt_alvdata TRANSPORTING NO FIELDS
          WITH KEY trkorr = <alv>-trkorr.
        IF sy-subrc = 0.
          lv_ndx = sy-tabix.
          APPEND INITIAL LINE TO lt_sel ASSIGNING FIELD-SYMBOL(<row>).
          <row>-index = lv_ndx.
        ENDIF.
      ENDLOOP.
      IF lines( lt_sel ) > 0.
        me->set_selected_rows_base(  lt_sel ).
      ENDIF.
    ENDIF.

  ENDMETHOD.

  METHOD init_buttons.
    " Default to disable
    mo_tbar->but_disable( '!APPTOC' ).
    mo_tbar->but_disable( '!TARGET' ).
    mo_tbar->but_disable( '!CLRTARG' ).
    mo_tbar->but_disable( '!DESELECT' ).

  ENDMETHOD.
  METHOD update_ui.
    " Update the buttons based on what is selected
    DATA lv_cnt TYPE i.
    DATA lv_sel_cnt TYPE i.
    DATA lv_target TYPE trkorr.
    DATA ls_sel_state TYPE ty_sel_state.
    DATA ls_curr TYPE ty_alvdata.



    init_buttons( ).
    "If nothing selected exit
    TRY.
        lv_sel_cnt = get_selected_row_count( ).
        ls_sel_state = get_sel_state( '' ).
      CATCH zcx_cop_alv_exception.
        CLEAR ls_sel_state.
    ENDTRY.

    IF gv_curr_target IS NOT INITIAL.
      mo_tbar->but_enable( '!CLRTARG' ).
    ENDIF.

    IF lv_sel_cnt > 0.
      mo_tbar->but_enable( '!DESELECT' ).
      " if single toc is <> curr target allow target button
      IF  ls_sel_state-single_toc IS NOT INITIAL
      AND ls_sel_state-single_toc <> gv_curr_target.
        mo_tbar->but_enable( '!TARGET' ).
      ENDIF.

      " source count = 1 and there is a target allow append
      IF  ls_sel_state-src_cnt >= 1
      AND ls_sel_state-target IS NOT INITIAL.
        mo_tbar->but_enable( '!APPTOC' ).
      ENDIF.
    ENDIF.
    mo_tbar->refresh( ).

    DATA lv_msg TYPE string.
    IF gv_save_message IS INITIAL.
      lv_msg = |{ ls_sel_state-src_cnt } Source(s) { ls_sel_state-src_text } Object(s) { ls_sel_state-src_obj_cnt }|.
      IF  ls_sel_state-target IS INITIAL.
        lv_msg = |{ lv_msg } No Target|.
      ELSE.
        lv_msg = |{ lv_msg } Target { ls_sel_state-target }|.
      ENDIF.
      gv_save_message = lv_msg.
    ENDIF.
    IF gv_save_message IS NOT INITIAL.
      IF gv_save_message_type IS INITIAL.
        gv_save_message_type = 'S'.
      ENDIF.
      MESSAGE gv_save_message TYPE gv_save_message_type.
    ENDIF.
    CLEAR gv_save_message.
    CLEAR gv_save_message_type.

  ENDMETHOD.

  METHOD new_toc.

    DATA lv_trkorr TYPE trkorr.

    " Create request if cancelled the result will be blank
    lv_trkorr = create_request( ).


    CHECK lv_trkorr IS NOT INITIAL.

    retval = abap_true.
    gv_save_message      = |TOC Transport { lv_trkorr } created|.
    gv_save_message_type = 'S'.
    "Set the target to new request
    gv_curr_target = lv_trkorr.
    IF get_selected_row_count( ) = 0.
      re_display( ).
      EXIT.
    ENDIF.
    "Do append processing
    append_request( lv_trkorr ).


  ENDMETHOD.

  METHOD create_request.

    DATA ls_alvdata TYPE ty_alvdata.
    DATA ls_new_req TYPE trwbo_request_header.
    DATA lv_title TYPE e07t-as4text.
    "Find first selected and use as prototype request then get the name
    TRY.
        get_first_selected_rowdata( CHANGING cs_data = ls_alvdata ). "First row is prototype
        lv_title   = ls_alvdata-as4text.
        IF lv_title+0(4) <> 'TOC:'.    "Ensure it starts with TOC:
          lv_title = 'TOC:' && lv_title.
        ENDIF.

      CATCH zcx_cop_alv_exception.
        lv_title = 'TOC:'.    "Ensure it starts with TOC:
    ENDTRY.
    "    mask_tcode( ).
    " Create the request.  it has built it cancellation
    CALL FUNCTION 'TR_REQUEST_MODIFY'
      EXPORTING
        iv_action            = 'CREA'
        iv_new_as4text       = lv_title
        iv_new_request_type  = 'T'
        iv_start_column      = 5
        iv_start_row         = 10
        iv_new_tarsystem     = p_tarsys
      IMPORTING
        es_new_request       = ls_new_req
      EXCEPTIONS
        cancelled_by_user    = 1
        no_authorization     = 2
        invalid_action       = 3
        invalid_request      = 4
        invalid_request_type = 5
        request_not_created  = 6
        request_not_deleted  = 7
        enqueue_failed       = 8
        db_access_error      = 9
        OTHERS               = 10.
    IF sy-subrc = 0.  " if it was created set it to return
      retval = ls_new_req-trkorr.
    ENDIF.
    "    unmask_tcode( ).
    IF retval IS INITIAL.
      gv_save_message =  'Action cancelled. No Transport was created'.
    ENDIF.

    gv_force_refresh = abap_true.

  ENDMETHOD.

  METHOD append_request.

    DATA lt_alv TYPE ty_alvdata_tab.
    DATA lv_rc  TYPE c.
    DATA lv_msg  TYPE string.
    DATA lv_msg2 TYPE string.
    DATA ls_sel_state TYPE ty_sel_state.

    TRY.  " Raise an error is selection scenario is a problem
        ls_sel_state = get_sel_state( iv_trkorr ).
      CATCH zcx_cop_alv_exception.
        EXIT.
    ENDTRY.

    " Auto Determine automatic target TOC if not in create mode
    " if create it is already the target
    " the first modifiable toc has already been removed
    " and moved to source so if any remain it is an error
    IF  ls_sel_state-new_target = abap_false
    AND ls_sel_state-target IS INITIAL
    AND ls_sel_state-mod_toc_cnt > 1.  "Only modifiable TOCs may be used in new transport  It shouldn't get this far
      MESSAGE |Multitple modifiable TOC's.  Nothing changed| TYPE 'S'.
      EXIT.
    ENDIF.

    " Ensure target is a TOC.
    READ TABLE gt_alvdata ASSIGNING FIELD-SYMBOL(<alv>)
      WITH KEY trkorr = ls_sel_state-target.
    IF sy-subrc = 0.
      IF <alv>-trfunction <> 'T'.
        MESSAGE |Target transports can only be TOC's.    Nothing changed| TYPE 'S'.
        EXIT.
      ENDIF.
    ENDIF.

    lv_msg2 = |Append { ls_sel_state-src_obj_cnt } object(s) from { ls_sel_state-src_cnt } task(s) { ls_sel_state-src_text }|.
    IF ls_sel_state-new_target = abap_true.
      lv_msg = |Transport { ls_sel_state-target } was created. { lv_msg2 }?|.
    ELSE.
      lv_msg = |{ lv_msg2 } into { ls_sel_state-target }?|.
    ENDIF.

    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar              = 'Append objects to TOC'
*       DIAGNOSE_OBJECT       = ' '
        text_question         = lv_msg
        text_button_1         = 'Open TOC'
        icon_button_1         = 'icon_display'
        text_button_2         = 'Return'
        icon_button_2         = 'icon_okay'
        default_button        = '1'
        display_cancel_button = 'X'
      IMPORTING
        answer                = lv_rc.

    IF lv_rc = 'A'.
      MESSAGE |Transport { ls_sel_state-target } is unchanged| TYPE 'S'.
      EXIT.
    ENDIF.

    gv_force_refresh = abap_true.

    "  Remember Transport as current Target it may
    "  be new or assumed.  Doesn't matter now.
    gv_curr_target = ls_sel_state-target.

    " copy all the objects selected into the target transport.
    LOOP AT ls_sel_state-sources ASSIGNING FIELD-SYMBOL(<trkorr>).
      CALL FUNCTION 'TR_COPY_COMM'
        EXPORTING
          wi_trkorr_from           = <trkorr>
          wi_trkorr_to             = ls_sel_state-target
          wi_without_documentation = 'X'
        EXCEPTIONS
          db_access_error          = 1
          trkorr_from_not_exist    = 2
          trkorr_to_is_repair      = 3
          trkorr_to_locked         = 4
          trkorr_to_not_exist      = 5
          trkorr_to_released       = 6
          user_not_owner           = 7
          no_authorization         = 8
          wrong_client             = 9
          wrong_category           = 10
          object_not_patchable     = 11
          OTHERS                   = 12.
      IF sy-subrc <> 0.
        MESSAGE |Error copying task { <trkorr> } to transport { iv_trkorr }| TYPE 'I'.
        EXIT.
      ENDIF.

    ENDLOOP.

    DATA lv_cnt TYPE i.
    lv_cnt = lines( ls_sel_state-sources ).
    gv_save_message = |Appended { lv_cnt } Transport(s) / Task(s) into { ls_sel_state-target }|.
    gv_save_message_type = 'S'.

    IF lv_rc = '1'.
      present_request( ls_sel_state-target ).
    ENDIF.
    re_display( ).


    "all done, refresh the screen data

  ENDMETHOD.

  METHOD get_children.

    DATA ls_request TYPE strhi_request_wd.

    ls_request-h-trkorr = iv_trkorr.
    CALL FUNCTION 'TRINT_READ_REQUEST_WD'
      EXPORTING
        iv_read_objs_keys = 'X'
      CHANGING
        cs_request_wd     = ls_request.

    retval = ls_request.
  ENDMETHOD.
  METHOD present_request.
    "Show the standard SAP Screen for the selected request
    " and or parent

    CALL FUNCTION 'TR_PRESENT_REQUEST'
      EXPORTING
        iv_trkorr    = iv_trkorr
        iv_highlight = 'X'.

  ENDMETHOD.

  METHOD set_target.
    " set the target Transport / Task
    " based on selection
    DATA ls_sel_state TYPE ty_sel_state.

    TRY.
        ls_sel_state = get_sel_state( '' ).
      CATCH zcx_cop_alv_exception.
        EXIT.
    ENDTRY.

    IF ls_sel_state-single_toc IS NOT INITIAL.
      gv_curr_target = ls_sel_state-single_toc.
      retval = abap_true.
    ENDIF.
    re_display( ).

  ENDMETHOD.

  METHOD constructor.
    super->constructor( EXPORTING i_data = gt_alvdata iv_dynnr = iv_dynnr ).
    SET HANDLER me->on_custom_setup FOR me.
    " Add Icons and Qinfo text to be used.\
    mo_icons->add_icon( EXPORTING iv_icon = icon_target_group          iv_qinfo_text = 'Current target TOC' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_routing               iv_qinfo_text = 'Workbench Transport' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_routing_sub_operation iv_qinfo_text = 'Workbench Task' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_ws_transport          iv_qinfo_text = 'TOC Transport' ).


    mo_icons->add_icon( EXPORTING iv_icon = icon_refresh         iv_dtext = 'Refresh' iv_function = '!REFRESH' iv_qinfo_text = 'Refresh Displayed Items' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_execute_object  iv_dtext = 'Open'    iv_function = '!OPEN'    iv_qinfo_text = 'Open the Transport' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_display_text    iv_dtext = 'Log'     iv_function = '!DISPLAY' iv_qinfo_text = 'Display release log' ).

    mo_icons->add_icon( EXPORTING iv_icon = icon_deselect_all    iv_dtext = 'Clear Selection' iv_function = '!DESELECT' iv_qinfo_text = 'Clear / Unselect All' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_create          iv_dtext = 'Create TOC...' iv_function = '!TOC'     iv_qinfo_text = 'Create a TOC' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_system_mark     iv_dtext = 'Mark Target'    iv_function = '!TARGET'  iv_qinfo_text = 'Mark TOC as Target' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_system_undo     iv_dtext = 'Clear Target'   iv_function = '!CLRTARG' iv_qinfo_text = 'Unmark TOC as Target' ).
    mo_icons->add_icon( EXPORTING iv_icon = icon_include_objects iv_dtext = 'Append TOC...'  iv_function = '!APPTOC'  iv_qinfo_text = 'Insert into TOC' ).

    gt_func = lcl_dom2vrm=>elm_2_vrm( 'TRFUNCTION' ).  "Extracts texts and values from domain
    gt_stat = lcl_dom2vrm=>elm_2_vrm( 'TRSTATUS' ).

  ENDMETHOD.

  METHOD on_selection_changed. "Fired if user selects a row after set_delay_selection millisecons

    update_ui( ).

  ENDMETHOD.

  METHOD on_custom_setup.
    "Fired prior to display of alv
    "and after alv->display method called
    "This event only fired if running in the SAP GUI not background
    ms_layo-info_fname = 'ROW_COLOR'.
    ms_layo-zebra = abap_false.
    ms_layo-no_merging = abap_false.
    SET HANDLER me->on_toolbar FOR me      ."Toolbar event handler
    ms_print_info-prnt_title = 0.


    add_sort( 'GROUPKEY').
    add_sort( EXPORTING iv_fieldname = 'STRKORR'        iv_sort = 'D' ).
    add_sort( 'SORTSEQ' ).
    add_sort( 'TRSTATUSTEXT' ).
    add_sort( 'TRFUNCTIONTEXT' ).
    add_sort( 'AS4TEXT' ).

    "Setup the toolbar buttons
    mo_tbar->add_cust_but( EXPORTING iv_function = '!REFRESH'  iv_position = '1' ).
    mo_tbar->add_separator( EXPORTING iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!OPEN'     iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!DISPLAY'  iv_position = '1' ).
    mo_tbar->add_separator( EXPORTING iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!DESELECT' iv_position = '1' ).
    mo_tbar->add_separator( EXPORTING iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!TARGET'   iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!CLRTARG'  iv_position = '1' ).
    mo_tbar->add_separator( EXPORTING iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!TOC'      iv_position = '1' ).
    mo_tbar->add_cust_but( EXPORTING iv_function = '!APPTOC'   iv_position = '1' ).
    mo_tbar->add_separator( EXPORTING iv_position = '1' ).

    init_buttons( ).

    "Customize field catalog items.
    set_fcat( EXPORTING iv_fieldname = 'ROW_ICON'        iv_propname = c_alv-coltext   iv_propvalue = 'Typ' ).
    set_fcat( EXPORTING iv_fieldname = 'ROW_ICON'        iv_propname = c_alv-outputlen iv_propvalue = '4' ).
    set_fcat( EXPORTING iv_fieldname = 'ROW_ICON'        iv_propname = c_alv-icon      iv_propvalue = 'X' ).
    set_fcat( EXPORTING iv_fieldname = 'AS4TEXT'         iv_propname = c_alv-outputlen iv_propvalue = '50' ).
    set_fcat( EXPORTING iv_fieldname = 'TRFUNCTIONTEXT'  iv_propname = c_alv-outputlen iv_propvalue = '20' ).
    set_fcat( EXPORTING iv_fieldname = 'TRKORR'          iv_propname = c_alv-coltext   iv_propvalue = 'Task' ).
    set_fcat( EXPORTING iv_fieldname = 'STRKORR'         iv_propname = c_alv-coltext   iv_propvalue = 'Transport' ).
    set_fcat( EXPORTING iv_fieldname = 'TRFUNCTIONTEXT'  iv_propname = c_alv-coltext   iv_propvalue = 'Function' ).
    set_fcat( EXPORTING iv_fieldname = 'TRSTATUSTEXT'    iv_propname = c_alv-coltext   iv_propvalue = 'Status' ).
    set_fcat( EXPORTING iv_fieldname = 'TARSYSTEM'       iv_propname = c_alv-coltext   iv_propvalue = 'Target' ).
    set_fcat( EXPORTING iv_fieldname = 'AS4USER'         iv_propname = c_alv-coltext   iv_propvalue = 'User' ).
    set_fcat( EXPORTING iv_fieldname = 'AS4DATE'         iv_propname = c_alv-coltext   iv_propvalue = 'Date' ).
    set_fcat( EXPORTING iv_fieldname = 'AS4TIME'         iv_propname = c_alv-coltext   iv_propvalue = 'Time' ).
    set_fcat( EXPORTING iv_fieldname = 'CHILDCNT'        iv_propname = c_alv-coltext   iv_propvalue = 'Items' ).
    set_fcat( EXPORTING iv_fieldname = 'LANGU'           iv_propname = c_alv-coltext   iv_propvalue = 'Language' ).
    set_fcat( EXPORTING iv_fieldname = 'AS4TEXT'         iv_propname = c_alv-coltext   iv_propvalue = 'Text' ).
    set_fcat( EXPORTING iv_fieldname = 'CLIENT'          iv_propname = c_alv-coltext   iv_propvalue = 'Client' ).
    set_fcat( EXPORTING iv_fieldname = 'CHILDREN'        iv_propname = c_alv-tech      iv_propvalue = 'X' ).
    set_fcat( EXPORTING iv_fieldname = 'ROW_COLOR'       iv_propname = c_alv-tech      iv_propvalue = 'X' ).
    set_fcat( EXPORTING iv_fieldname = 'SORTSEQ'         iv_propname = c_alv-coltext   iv_propvalue = 'Seq #').

    set_fcat( iv_fieldname = 'ROW_ICON'       iv_propname = c_alv-col_pos iv_propvalue = '1' ).
    set_fcat( iv_fieldname = 'TRFUNCTIONTEXT' iv_propname = c_alv-col_pos iv_propvalue = '2' ).
    set_fcat( iv_fieldname = 'STRKORR'        iv_propname = c_alv-col_pos iv_propvalue = '3' ).
    set_fcat( iv_fieldname = 'SORTSEQ'        iv_propname = c_alv-col_pos iv_propvalue = '4' ).
    set_fcat( iv_fieldname = 'TRKORR'         iv_propname = c_alv-col_pos iv_propvalue = '5' ).
    set_fcat( iv_fieldname = 'TRSTATUSTEXT'   iv_propname = c_alv-col_pos iv_propvalue = '6' ).
    set_fcat( iv_fieldname = 'AS4TEXT'        iv_propname = c_alv-col_pos iv_propvalue = '7' ).

    set_fcat_many( iv_fieldname = 'AS4USER|TARSYSTEM|AS4DATE|AS4TIME|CHILDCNT'
      iv_propname = c_alv-outputlen iv_propvalue = '10' ).
    set_fcat_many( iv_fieldname = 'TRKORR|STRKORR|TRSTATUSTEXT'
      iv_propname = c_alv-outputlen iv_propvalue = '12' ).
    set_fcat_many( iv_fieldname = 'TRSTATUS|TRFUNCTION|CHILDREN|LANGU|CLIENT|TRFUNKEY|TRSTATKEY|ROW_COLOR|PARENT|GROUPKEY'
      iv_propname = c_alv-no_out iv_propvalue = 'X' ).

    " If not running in background enable the custom setup event
    "    IF offline( ) IS INITIAL.

    "    ENDIF.
    SET HANDLER on_top_of_page FOR me.
    SET HANDLER on_print_top_of_list FOR me.
    SET HANDLER on_cell_changed FOR me.
    SET HANDLER on_selection_changed FOR me.
    SET HANDLER on_double_click FOR me      .
    IF sy-batch = abap_true.
      EXIT.
    ENDIF.
    "Setup Delayed Event handler
    register_delayed_event( mc_evt_delayed_change_select ).
    register_delayed_event( mc_evt_delayed_move_curr_cell ).
    "Set Delay time in Milliseconds for delayed events
    set_delay_selection( 300 ).
    set_delay_cell_chg( 300 ).
  ENDMETHOD.

  METHOD on_cell_changed.   "Event fired if user moves focus to a cell
    "                           :after set_delay_cell_chg millisecons
    DATA lv_nam TYPE string.
    lv_nam = get_active_cellid( ).

  ENDMETHOD.

  METHOD on_user_command.  "Fired if user clicks a custom toolbar item
    " Tool bar button was clicked
    DATA lt_lvc_rows TYPE lvc_t_row.

    CASE e_ucomm.
      WHEN '!OPEN'.
        open( ).
      WHEN '!TOC'.
        new_toc( ).
      WHEN '!APPTOC'.
        append_request( '' ).
      WHEN '!DESELECT'.
        set_selected_rows_base( lt_lvc_rows ).
      WHEN '!DISPLAY'.
        display_log( ).
      WHEN '!REFRESH'.
        re_display( abap_true ).
      WHEN '!TARGET'.
        set_target( ).
      WHEN '!CLRTARG'.
        CLEAR gv_curr_target.
        re_display( ).
    ENDCASE.
    update_ui( ).
  ENDMETHOD.

  METHOD on_double_click.  "Event fired if a cell is double clicked

*    DATA lr_dat TYPE REF TO data.
*    DATA lv_nam TYPE string.
*    DATA lv_msg TYPE string.
*    FIELD-SYMBOLS <dat> TYPE any.
*    lv_nam = get_active_cellid( ).            "Retrieve active cell name
*    lr_dat = get_active_celldata( ).          "Retrieve active cell value
*    ASSIGN lr_dat->* TO <dat>.
    open( ).

  ENDMETHOD.

  METHOD open.

    DATA lr_row TYPE ty_alvdata.
    " get the row double clicked and present the request
    TRY.
        get_active_rowdata( CHANGING cs_data = lr_row ).
        present_request( lr_row-trkorr ).
      CATCH  zcx_cop_alv_exception.
        EXIT.
    ENDTRY.
    re_display( abap_true ).
  ENDMETHOD.

  METHOD on_print_top_of_list.
    WRITE / 'xx top of list'.
  ENDMETHOD.

ENDCLASS.
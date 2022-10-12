prompt --application/set_environment
set define off verify off feedback off
whenever sqlerror exit sql.sqlcode rollback
--------------------------------------------------------------------------------
--
-- Oracle APEX export file
--
-- You should run the script connected to SQL*Plus as the Oracle user
-- APEX_220100 or as the owner (parsing schema) of the application.
--
-- NOTE: Calls to apex_application_install override the defaults below.
--
--------------------------------------------------------------------------------
begin
wwv_flow_imp.import_begin (
 p_version_yyyy_mm_dd=>'2022.04.12'
,p_release=>'22.1.0'
,p_default_workspace_id=>2236596970938825
,p_default_application_id=>102
,p_default_id_offset=>14003701375314693
,p_default_owner=>'SGD_DEV'
);
end;
/
 
prompt APPLICATION 102 - Experiencing APEX Plugins (SavetoGoogleDrive)
--
-- Application Export:
--   Application:     102
--   Name:            Experiencing APEX Plugins (SavetoGoogleDrive)
--   Date and Time:   11:21 Wednesday October 12, 2022
--   Exported By:     ADMIN
--   Flashback:       0
--   Export Type:     Component Export
--   Manifest
--     PLUGIN: 14139007436130406
--   Manifest End
--   Version:         22.1.0
--   Instance ID:     713482219278393
--

begin
  -- replace components
  wwv_flow_imp.g_mode := 'REPLACE';
end;
/
prompt --application/shared_components/plugins/process_type/com_luisricardo_apexocr
begin
wwv_flow_imp_shared.create_plugin(
 p_id=>wwv_flow_imp.id(14139007436130406)
,p_plugin_type=>'PROCESS TYPE'
,p_name=>'COM.LUISRICARDO.APEXOCR'
,p_display_name=>'Oracle Apex OCR with GDrive API'
,p_supported_ui_types=>'DESKTOP'
,p_supported_component_types=>'APEX_APPLICATION_PAGE_PROC:APEX_APPL_AUTOMATION_ACTIONS'
,p_plsql_code=>wwv_flow_string.join(wwv_flow_t_varchar2(
'-- =============================================================================',
'--',
'--  Author: Luis Ricardo Oliveira',
'--  Date: 11.10.2022',
'--  This plug-in lets users perform OCR on uploaded documents with Google Drive API v3.',
'--  ',
'--',
'--  License: MIT',
'--',
'--  GitHub: https://github.com/lordguerdo',
'--',
'-- =============================================================================',
'',
'function perform_ocr ( p_process in apex_plugin.t_process, p_plugin in apex_plugin.t_plugin) return apex_plugin.t_process_exec_result ',
'as',
'   l_result                apex_plugin.t_process_exec_result;',
'',
'   -- apex attributes',
'   l_refresh_token         p_process.attribute_01%type := p_process.attribute_01;',
'   l_client_id             p_process.attribute_02%type := p_process.attribute_02;',
'   l_client_secret         p_process.attribute_03%type := p_process.attribute_03;',
'   l_collection_name       p_process.attribute_04%type := p_process.attribute_04;',
'   l_del_file_after        p_process.attribute_05%type := p_process.attribute_05;',
'   l_filebrowse_item       p_process.attribute_06%type := p_process.attribute_06;',
'',
'   -- general attributes',
'   l_authorization         varchar2(1000);',
'   l_file_names            apex_t_varchar2;',
'   l_file_id               varchar2(1000);',
'',
'   -- functions',
'    -- get credentials',
'    function get_credentials(t varchar2, i varchar2, s varchar2) return varchar2',
'    is',
'       -- apex ws attributes',
'       l_rest_authurl          varchar2(1000);',
'       l_access_token          varchar2(1000);',
'       l_parm_names            apex_application_global.vc_arr2;',
'       l_parm_values           apex_application_global.vc_arr2;',
'       l_response_clob         clob;',
'    begin',
'       l_parm_names  (1)    := ''refresh_token'';',
'       l_parm_values (1)    := t;',
'       l_parm_names  (2)    := ''client_id'';',
'       l_parm_values (2)    := i;',
'       l_parm_names  (3)    := ''client_secret'';',
'       l_parm_values (3)    := s;',
'       l_parm_names  (4)    := ''grant_type'';',
'       l_parm_values (4)    := ''refresh_token'';',
'       l_rest_authurl       := ''https://www.googleapis.com/oauth2/v4/token'';',
'',
'       apex_web_service.g_request_headers.delete ();',
'       apex_web_service.g_request_headers (1).name      := ''Content-Type'';',
'       apex_web_service.g_request_headers (1).value     := ''application/x-www-form-urlencoded'';',
'',
'       l_response_clob :=',
'          apex_web_service.make_rest_request (p_url           => l_rest_authurl,',
'                                              p_http_method   => ''POST'',',
'                                              p_parm_name     => l_parm_names,',
'                                              p_parm_value    => l_parm_values);',
'',
'      SELECT JSON_VALUE (l_response_clob, ''$.access_token'') INTO l_access_token FROM DUAL;',
'',
'      return l_access_token;',
'',
'        EXCEPTION WHEN OTHERS THEN return NULL;',
'    end get_credentials;',
'',
'    function upload_as_document(n varchar2, t varchar2, m varchar2, b blob) return varchar2',
'    is',
'       lc_response      clob;',
'       lm_multipart     apex_web_service.t_multipart_parts;',
'       lc_json          clob            := ''{"name": "''||n||''","mimeType": "application/vnd.google-apps.document"}'';   ',
'       lv_filename      varchar2(1000)  := n;',
'       lv_base_url      varchar2(100)   := ''https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart''; ',
'       l_blob           blob            := b;',
'       l_id             varchar2(100);',
'    begin',
'',
'        apex_web_service.g_request_headers.delete ();',
'        apex_web_service.g_request_headers (1).name     := ''Content-Type'';',
'        apex_web_service.g_request_headers (1).value    := ''multipart/related; boundary=metadata_file'';',
'        apex_web_service.g_request_headers (2).name     := ''Authorization'';',
'        apex_web_service.g_request_headers (2).value    := ''Bearer ''||t;',
'',
'        apex_web_service.APPEND_TO_MULTIPART (',
'                p_multipart    => lm_multipart,',
'                p_name         => ''--metadata--'',',
'                p_content_type => ''application/json; charset=UTF-8'',',
'                p_body         => lc_json );',
'  ',
'        apex_web_service.APPEND_TO_MULTIPART (',
'                p_multipart    => lm_multipart,',
'                p_name         => ''--file--'',',
'                p_filename     => lv_filename,',
'                p_content_type => m,',
'                p_body_blob    => l_blob );',
'',
'        lc_response  := apex_web_service.make_rest_request(p_url => lv_base_url,',
'                                                           p_http_method => ''POST'',',
'                                                           p_body_blob => apex_web_service.generate_request_body(lm_multipart)); ',
'                                   ',
'        SELECT JSON_VALUE (lc_response, ''$.id'') INTO l_id FROM DUAL;',
'        ',
'        return l_id;',
'',
'        EXCEPTION WHEN OTHERS THEN return null;',
'',
'    end upload_as_document;',
'',
'    function get_file_content(t in varchar2, i varchar2) return clob',
'    is',
'        l_ocr_content       clob;',
'    begin',
'        apex_web_service.g_request_headers.delete ();',
'        apex_web_service.g_request_headers (1).name := ''Authorization'';',
'        apex_web_service.g_request_headers (1).value := ''Bearer ''||t;',
'',
'        l_ocr_content := ',
'            apex_web_service.make_rest_request(''https://www.googleapis.com/drive/v3/files/''||i||''/export?mimeType=text%2Fplain'',''GET'');',
'',
'            return l_ocr_content;',
'',
'            EXCEPTION WHEN OTHERS THEN return null;',
'    end get_file_content;',
'',
'    procedure delete_file(t in varchar2, i in varchar2)',
'    is',
'        lc_response      clob;',
'    begin',
'        apex_web_service.g_request_headers.delete ();',
'        apex_web_service.g_request_headers (1).name := ''Authorization'';',
'        apex_web_service.g_request_headers (1).value := ''Bearer ''||t;',
'        apex_web_service.g_request_headers (2).name := ''Accept'';',
'        apex_web_service.g_request_headers (2).value := ''application/json'';',
'        ',
'        lc_response := ',
'            APEX_WEB_SERVICE.MAKE_REST_REQUEST(''https://www.googleapis.com/drive/v3/files/''||i,''DELETE'');',
'        ',
'        EXCEPTION WHEN OTHERS THEN null;                     ',
'                                   ',
'    end delete_file;',
'',
'BEGIN',
'    -- start the collection',
'    if not apex_collection.collection_exists(l_collection_name) then',
'        apex_collection.create_collection(l_collection_name);',
'    end if;',
'    ',
'    l_authorization     := get_credentials(l_refresh_token, l_client_id, l_client_secret);',
'',
'    l_file_names        := apex_string.split(v(l_filebrowse_item),'':'');',
'    ',
'    for f in 1..l_file_names.COUNT',
'        loop',
'            for tmpFile in(select filename, mime_type, blob_content from apex_application_temp_files where name = l_file_names(f))',
'                loop',
'                    commit;',
'                    l_file_id   := upload_as_document(tmpFile.filename, l_authorization, tmpFile.mime_type, tmpFile.blob_content);',
'',
'                    apex_collection.add_member( p_collection_name => l_collection_name,',
'                                                p_c001            => tmpFile.filename,',
'                                                p_c002            => tmpFile.mime_type,',
'                                                p_c003            => l_file_id,',
'                                                p_d001            => sysdate,',
'                                                p_clob001         => get_file_content(l_authorization,l_file_id),',
'                                                p_blob001         => tmpFile.blob_content ',
'                                                );',
'',
'                    if l_del_file_after = ''Y'' then',
'                        delete_file(l_authorization,l_file_id);',
'                    end if;',
'',
'                end loop;',
'        end loop;',
'        delete from apex_application_temp_files;',
'        commit;',
'',
'        l_result.success_message    := l_file_names.COUNT||'' File(s) loaded.'';',
'',
'        return l_result;',
'',
'    exception when others then ',
'         l_result.success_message:=''An error occurred.'';',
'         return l_result;',
'END perform_ocr;'))
,p_api_version=>2
,p_execution_function=>'perform_ocr'
,p_substitute_attributes=>true
,p_subscribe_plugin_settings=>true
,p_version_identifier=>'1.0'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14144481433784023)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>1
,p_display_sequence=>10
,p_prompt=>'Refresh Token'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Refresh token obtained from Google OAuth2'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14145211624789088)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>2
,p_display_sequence=>20
,p_prompt=>'Client ID'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Client ID obtained from Google Console API'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14146007102792409)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>3
,p_display_sequence=>30
,p_prompt=>'Client Secret'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Client Secret obtained from Google Console API'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14147759344804820)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>4
,p_display_sequence=>40
,p_prompt=>'Collection Name'
,p_attribute_type=>'TEXT'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Name your collection here, then you will can check for the file and OCR.'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14148131371807657)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>5
,p_display_sequence=>50
,p_prompt=>'Delete File After Upload?'
,p_attribute_type=>'SELECT LIST'
,p_is_required=>true
,p_default_value=>'Y'
,p_is_translatable=>false
,p_lov_type=>'STATIC'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(14148454088808539)
,p_plugin_attribute_id=>wwv_flow_imp.id(14148131371807657)
,p_display_sequence=>10
,p_display_value=>'Yes'
,p_return_value=>'Y'
);
wwv_flow_imp_shared.create_plugin_attr_value(
 p_id=>wwv_flow_imp.id(14148837158809265)
,p_plugin_attribute_id=>wwv_flow_imp.id(14148131371807657)
,p_display_sequence=>20
,p_display_value=>'No'
,p_return_value=>'N'
);
wwv_flow_imp_shared.create_plugin_attribute(
 p_id=>wwv_flow_imp.id(14154413581844300)
,p_plugin_id=>wwv_flow_imp.id(14139007436130406)
,p_attribute_scope=>'COMPONENT'
,p_attribute_sequence=>6
,p_display_sequence=>60
,p_prompt=>'File Browse Item'
,p_attribute_type=>'PAGE ITEM'
,p_is_required=>true
,p_is_translatable=>false
,p_help_text=>'Specify File Browse Item for uploads. Ensure APEX_APPLICATION_TEMP_FILES table storage is specified.'
);
end;
/
prompt --application/end_environment
begin
wwv_flow_imp.import_end(p_auto_install_sup_obj => nvl(wwv_flow_application_install.get_auto_install_sup_obj, false));
commit;
end;
/
set verify on feedback on define on
prompt  ...done

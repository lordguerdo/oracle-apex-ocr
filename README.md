Oracle Apex OCR with GDrive API

This plugin allows users to OCR images and documents through Google Drive API v3, saving the result in a collection.

PRE-REQUISITES

Ensure you have configured REST APIs for your google drive account to retrieve refresh token,Client ID, and Client secret for use in the Plugin. 
I have attached a step by step guide (Guide.pdf).

PLUGIN INSTALLATION

Import process type plugin (process_type_plugin_com_luisricardo_apexocr.sql) into your application and include as part of your submit page process

PLUGIN USE

On an APEX Application page: 

1. Create a File Browse page item on APEX app page and choose TABLE APEX_APPLICATION_TEMP_FILES for storage type.
2. Create a Classic, Interactive or Grid report using an APEX COLLECTION, using the Collection Name with the name of your choice.
	Example: SELECT SEQ_ID, C001, C002, C003, D001, CLOB001, BLOB001 FROM APEX_COLLECTIONS WHERE COLLECTION_NAME = 'OCR_SAMPLE'
		(1) SEQ_ID Is the sequence number in your collection
		(2) C001 : Is the original filename
		(3) C002 : Is the file Mime Type
		(4) C003 : Is the Google Drive ID for the uploaded file
		(5) D001 : Is the date of the operation
		(6) CLOB001 : Is the Text extracted from uploaded file
		(7) BLOB001 : Is the Binary file
3. Create page process of type plugin and select "Oracle APEX OCR with GDrive API" plugin.
4. Ensure the following settings information are entered:
   (a) Refresh Token (Mandatory) : Available from google drive rest api configuration.
   (b) Client ID (Mandatory) : Available from google drive rest api configuration.
   (c) Client Secret (Mandatory) : Available from google drive rest api configuration.
   (d) Collection Name : Name your collection here (as shown in step 2), then you will can check for the file and OCR.
   (e) Delete Files After Upload : Choose this option if you want the file being deleted from Google Drive after the OCR Operation. Yes = Delete, No = Store the file
   (f) File Browse Item (Mandatory) : Item created in step 1

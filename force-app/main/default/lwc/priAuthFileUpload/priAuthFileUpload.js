import { LightningElement, api } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { showToast, openFileUploadHelper, updateFileList } from 'c/fileUploaderHelper';
import uploadFile from '@salesforce/apex/PriAuthFileUpload.uploadFile';
import fetchContentDocument from '@salesforce/apex/PriAuthFileUpload.getLinkedFile';
export default class PriAuthFileUpload extends LightningElement {
    @api recordId;
    fileData;
    fileName;
    fileType;
    fileURL;
    error;
    fileExists = false;
    lstOption = [];
    showSubmit = false;
    showLoading = false;



    connectedCallback() {
        this.refreshView();
    }


    openfileUpload(event) {
        openFileUploadHelper(event, this.recordId, (error, fileData) => {
            if (error) {
                 showToast(this, {
                    title: 'Error',
                    message: error,
                    variant: 'error'
                });
                
                return;
            }
            this.fileData = fileData;
            this.showSubmit = true;
        });
    }

 handleClick() {
        this.showLoading = true;
        this.fileExists = false;
        const { base64, filename, recordId } = this.fileData;
        uploadFile({ base64, filename, recordId })
        .then(() => {
            this.fileData = null
            let title = `${filename} uploaded successfully!!`;
            showToast(this, {
                    title: 'Success',
                    message: title,
                    variant: 'success'
                });
            this.lstOption = [];
            this.refreshView();
        })
        .catch(error => {
            showToast(this, {
                title: 'Error',
                message: error,
                variant: 'error'
            });
        });
    }


    refreshView() {
        let recordId = this.recordId;
        fetchContentDocument({ recordId })
            .then(result => {
                updateFileList(this, result);
            }).catch(error => {
                showToast(this, {
                    title: 'Error',
                    message: error,
                    variant: 'error'
                });
            });
    }

    handleDelete(event) {
        deleteRecord(event.target.value)
            .then(() => {
                 showToast(this, {
                    title: 'Success',
                    message: 'File has been removed successfully',
                    variant: 'success'
                });
                this.refreshView();
            })
            .catch(error => {
                 showToast(this, {
                    title: 'You are not allowed to delete this record.',
                    message: error,
                    variant: 'error'
                });
            });
    }


}
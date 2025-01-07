import { ShowToastEvent } from 'lightning/platformShowToastEvent';

const showToast = (component, { title, message, variant }) => {
    const toastEvent = new ShowToastEvent({
        title,
        message,
        variant
    });
    component.dispatchEvent(toastEvent);
};

const openFileUploadHelper = (event, recordId, callback) => {
    const file = event.target.files[0];
    if (!file) {
        callback('No file selected', null);
        return;
    }

    const reader = new FileReader();
    reader.onload = () => {
        const base64 = reader.result.split(',')[1];
        const fileData = {
            filename: file.name,
            base64: base64,
            recordId: recordId
        };
        callback(null, fileData);
    };

    reader.onerror = () => callback('Error reading the file', null);
    reader.readAsDataURL(file);
};
const updateFileList = (component, result) => {
    if (result) {
        component.lstOption = result;
        component.fileExists = true;
        component.showSubmit = false;
        component.showLoading = false;
    }
};
export { showToast, openFileUploadHelper, updateFileList };
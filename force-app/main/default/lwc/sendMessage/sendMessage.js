import { LightningElement, wire, api } from 'lwc';
import USER_ID from '@salesforce/user/Id';
import getCareProgramTeamMember from '@salesforce/apex/J_SendMessage.getCareProgramTeamMember';
import sendMessage from '@salesforce/apex/J_SendMessage.sendMessagedata';
import checkContentSize from '@salesforce/apex/J_SendMessage.contentSize';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
export default class SendMessage extends NavigationMixin(LightningElement) {

    UserId = USER_ID;
    teamMemberOptions = [];
    maxCharacters = 250;
    @api recordId;
    @api myRecordId;
    attachmentIds = [];
    searchTerm = '';
    showOptions = false;
    selectedRecipient = '';
    attachmentIdsArray;
    message = '';
    showValidationMessage = false;
    showMaxLengthValidation = false;
    showRecipientValidationMessage = false;
    acceptedFormats = ['.pdf', '.png', '.doc'];


    @wire(getCareProgramTeamMember, { userId: '$UserId' })
    wiredAccId({ data, error }) {
        if (data) {
            try {
                this.teamMemberOptions = data.map(member => ({
                    label: member.Name,
                    value: member.UserId
                }));
            } catch (err) {
                this.showToast('Error', 'Failed to process team member data '+ err.message,'error');
            }
        } else if (error) {
            this.showToast('Error', 'There was an error fetching care program team members '+ error.body.message,'error');
        }
    }
    

    connectedCallback() {
        this.clearAttachmentIds();
        this.updateMessageLength();
    }

    clearAttachmentIds() {
        this.attachmentIds = [];
    }



    handleSearchChange(event) {
        const newSearchTerm = event.target.value.toLowerCase();
        if (newSearchTerm !== this.searchTerm) {
            this.searchTerm = newSearchTerm;
            this.showOptions = !!newSearchTerm && this.filteredOptions.length > 0;
        }

    }

    get filteredOptions() {
        let options = this.teamMemberOptions.filter(option =>
            option.label.toLowerCase().includes(this.searchTerm)
        );
        if (!this.searchTerm) {
            options.unshift({ label: 'All Users', value: 'all' });
        }
        if (options.length === 0) {
            options.push({ label: 'No User Found', value: 'none', disabled: true });
        }
        return options;
    }

    handleOptionSelect(event) {
        const selectedValue = event.currentTarget.dataset.value;
        // If the selected option is already selected, deselect it
        const options = this.filteredOptions.find(opt => opt.value === selectedValue);
        if (options && options.disabled) {
            return; // Do nothing if the option is disabled
        }
        if (this.selectedRecipient === selectedValue) {
            this.clearSelectedRecipient();
        } else {
            // Otherwise, select the clicked option
            this.recipientId = selectedValue;
            const selectedOption = this.teamMemberOptions.find(opt => opt.value === this.recipientId);
            this.selectedRecipient = selectedOption ? selectedOption.label : '';
            this.searchTerm = ''; // Clear the search term when an option is selected
            this.showOptions = false;

            // Add the selected-option class to the clicked option
            event.currentTarget.classList.add('selected-option');
        }
    }


    handleRecipientBlur(event) {
        if (!event.target.value) {
            this.recipientId = null;
            this.selectedRecipient = '';
            this.showOptions = false;
            if (this.searchTerm) {
                this.showOptions = true;
            }
        }
    }

    updateMessageLength() {
        // Check if message exceeds the maximum character limit
        if (this.message && this.message.length > 250) {
            this.message = this.message.slice(0, 250); // Truncate message to 250 characters
            this.showMaxLengthValidation = true;
        } else {
            this.showMaxLengthValidation = false;
        }
    }

    handleMessageChange(event) {
        this.message = event.target.value;
        if (this.message.length > this.maxCharacters) {
            this.message = this.message.slice(0, this.maxCharacters);
            this.showMaxLengthValidation = true;
        } else {
            this.showMaxLengthValidation = false;
        }
    }

    get allowedFormats() {
        return ['.pdf', '.png'];
    }

    handleUploadFinished(event) {
        const uploadedFiles = event.detail.files;
        uploadedFiles.forEach((file) =>
        checkContentSize({ cid: file.documentId })
            .then((result) => {
                if (result === 'ERROR') {
                    this.showToast('Error', 'File exceeds the size limit of 25MB.', 'error');
                } else {
                    this.attachmentIds.push({
                        id: file.documentId,
                        name: file.name,
                    });
                }
            })
            .catch(() => {
                this.showToast('Error', 'An error occurred while checking the file size.', 'error');
            })
    );
       
    }



    handleRemoveFile(event) {
        const fileId = event.currentTarget.dataset.id;
        this.attachmentIds = this.attachmentIds.filter(attachment => attachment.id !== fileId);

    }

    sendData() {
        if (this.validateData()) {
            const messageData = {
                recipientId: this.recipientId,
                message: this.message,
                sender: this.UserId,
                taskId: this.recordId
            };
            if (this.attachmentIds.length > 0) {
                messageData.attachmentIds = this.attachmentIds.map(attachment => attachment.id);
            }
            sendMessage(messageData)
                .then(() => {
                    this.showToast('Success', 'Message sent successfully.', 'success');
                    if (!import.meta.env.SSR) {
                        window.location.reload(); // Reload the page only in a browser environment
                    }

                })
                .catch(error => {
                    this.showToast('Error', 'An error occurred while sending the message.'+error.body.message, 'error');

                });
        }
    }


    validateData() {
        let isValid = true;

        if (!this.selectedRecipient.trim()) {
            this.showRecipientValidationMessage = true;
            isValid = false;
        } else {
            this.showRecipientValidationMessage = false;
        }

        if (!this.message.trim()) {
            this.showValidationMessage = true;
            isValid = false;
        } else {
            this.showValidationMessage = false;
        }

        if (this.message.length > this.maxCharacters) {
            this.showMaxLengthValidation = true;
            isValid = false;
        } else {
            this.showMaxLengthValidation = false;
        }

        return isValid;
    }

    previewHandler(event) {
        const attachmentId = event.target.dataset.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__namedPage',
            attributes: {
                pageName: 'filePreview'
            },
            state: {
                selectedRecordId: attachmentId
            }
        });
    }
    clearForm() {
        this.recipientId = '';
        this.message = '';
        this.attachmentIds = [];
        this.selectedRecipient = '';
    }

    showToast(title, message, variant) {
        if (!import.meta.env.SSR) {
            const event = new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable',
            });
            this.dispatchEvent?.(event);
        }
    }
    get remainingCharactersClass() {
        if (this.message.length === 250) {
            this.showMaxLengthValidation = true;
            return 'slds-text-color_error';
        }
        this.showMaxLengthValidation = false;
        return 'slds-text-color_default';

    }

    get remainingCharacters() {
        return `${this.maxCharacters - this.message.length} characters remaining`;
    }

    clearSelectedRecipient() {
        this.recipientId = null;
        this.selectedRecipient = '';
        // Remove the selected-option class from all options
        const options = this.template.querySelectorAll('.slds-listbox__item');
        options.forEach(option => {
            option.classList.remove('selected-option');
        });
    }
}
import { LightningElement, wire, api } from 'lwc';
import getMessages from '@salesforce/apex/J_SendMessageController.getMessages';
import getMessageAttachments from '@salesforce/apex/J_SendMessage.getMessageAttachments';
import { NavigationMixin } from 'lightning/navigation';
import sendEmail from '@salesforce/apex/J_SendMessage.getCareProgramTeamMember';
import USER_ID from '@salesforce/user/Id';
import { refreshApex } from '@salesforce/apex';

export default class Viewmessage extends NavigationMixin(LightningElement) {
    @api recordId;
    messages = [];
    selectedMessages = {};
    error;
    UserId = USER_ID;
    showModal = false;
    showModalopen = false;
    pdfAttachments = [];
    teamMemberOptions = [];
    selectedMessageContent = '';
    recipientId;
    selectedMessageId;
    searchTerm = '';
    showOptions = false;
    fromDate;
    toDate;
    selectedRecipient = '';
    attachmentsAvailable;
    wiredMessagesResult;

    columns = [
        { label: 'From Name', fieldName: 'fromName', type: 'text' },
        { label: 'Sent To Name', fieldName: 'sentToName', type: 'text' },
        //{ label: 'Message', fieldName: 'messageContent', type: 'text' },
        {   
            label: 'Message',
            fieldName: 'messageContent',
            type: 'custom',
            sortable: false,
            typeAttributes: {
                template: 'messageTemplate',
                action: { label: 'Open Modal', name: 'openModal' } // Action to open modal
            },
            wrapText: true
        },
        
      { 
        label: 'Sent/Received Time', 
        fieldName: 'createdDate', 
        type: 'date',
        sortable: false,
        typeAttributes: {
            year: "numeric",
            month: "2-digit",
            day: "2-digit",
            hour: "2-digit",
            minute: "2-digit",
            hour12: true
        }
    },
        {   label: 'Attachments',
            type: 'button-icon', 
            typeAttributes: {
                iconName: 'utility:preview',
                name: 'checkAttachments',
                title: 'Check Attachments',
                variant: 'brand',
                hidden: '$attachmentsAvailable',
                alternativeText: 'View Attachments'
            }
        },
        
    ];
    
    connectedCallback() {
        this.refreshMessages();
    }
    messageTemplate(value, row) {
        return `<div style="max-width: 100%; word-wrap: break-word; overflow-wrap: break-word; white-space: pre-wrap;" 
                    data-messageid="${row.messageId}" 
                    onclick={messageCellClick}>
                    ${value}
                </div>`;
    }
    @wire(sendEmail, { userId: '$UserId' })
    wiredAccId({ data}) {
        if (data) {
            this.teamMemberOptions = data.map(member => ({
                label: member.Name,
                value: member.UserId
            }));
           
        }
    }

    @wire(getMessages, { recordId: '$recordId', userId: '$UserId' })
    wiredMessages({ error, data }) {
        this.wiredMessagesResult = { error, data };
        if (data) {
            this.messages = data.map(message => ({
                messageId: message.messageId,
                fromId: message.fromId,
                fromName: message.fromName,
                sentToId: message.sentToId,
                sentToName: message.sentToName,
                messageContent: message.messageContent,
                createdDate: message.createdDate ? new Date(message.createdDate).toISOString() : null
            }));
        
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.messages = [];
        }
    }

    handleFromDateChange(event) {
        const selectedDate = event.target.value;
        this.fromDate = selectedDate ? new Date(selectedDate).toISOString() : null;
    }

    handleToDateChange(event) {
        const selectedDate = event.target.value;
        this.toDate = selectedDate ? new Date(selectedDate).toISOString() : null;
    }

    handleDateRefresh() {
        this.fromDate = null;
        this.toDate = null;
    }

     handleOptionSelect(event) {
    const selectedValue = event.currentTarget.dataset.value;
    const selectedOption = this.filteredOptions.find(opt => opt.value === selectedValue);
    if (selectedOption && selectedOption.disabled) {
        return; // Do nothing if the option is disabled
    }
    
    // If the selected option is already selected, deselect it
    if (this.selectedRecipient === selectedValue) {
        this.clearSelectedRecipient();
    } else {
        // Otherwise, select the clicked option
        this.recipientId = selectedValue;
        this.selectedRecipient = this.teamMemberOptions.find(option => option.value === this.recipientId).label;
        this.searchTerm = ''; // Clear the search term when an option is selected
        this.showOptions = false;

        // Add the selected-option class to the clicked option
        event.currentTarget.classList.add('selected-option');
    }
}

    handleSearchChange(event) {
        const newSearchTerm = event.target.value.toLowerCase();
        if (newSearchTerm !== this.searchTerm) {
             this.searchTerm = newSearchTerm;
             this.showOptions = !!newSearchTerm && this.filteredOptions.length > 0;

        }
       
    }
    get dropdownClass() {
        return `slds-dropdown slds-dropdown_length-with-icon-10 slds-dropdown_fluid ${this.showOptions ? 'slds-show' : 'slds-hide'}`;
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
// toggleCheckbox(messageId) {
//     if (this.selectedMessages.hasOwnProperty(messageId)) {
//         delete this.selectedMessages[messageId]; // Remove message ID from selected messages
//     } else {
//         this.selectedMessages[messageId] = true; // Add message ID to selected messages
//     }
// }

toggleCheckbox(messageId) {
    if (Object.hasOwn(this.selectedMessages, messageId)) {
        delete this.selectedMessages[messageId]; // Remove message ID from selected messages
    } else {
        this.selectedMessages[messageId] = true; // Add message ID to selected messages
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

  get filteredMessages() {
    if (this.searchTerm && this.filteredOptions.some(option => option.value === 'none')) {
            return [];
        }   
    
    return this.messages.filter(message => {
        let messageDate = new Date(message.createdDate);
        let fromDate = this.fromDate ? new Date(this.fromDate) : null;
        let toDate = this.toDate ? new Date(this.toDate) : null;

       

        // Adjust toDate to include the end of the day
        if (toDate) {
            toDate.setHours(23, 59, 59, 999);
        }

        if (fromDate && toDate) {
            // Adjust comparison to include dates up to and including the end date
            return messageDate >= fromDate && messageDate <= toDate; // Compare dates only, without adding an extra day
        } else if (fromDate) {
            return messageDate >= fromDate;
        } else if (toDate) {
            return messageDate <= toDate;
        }
        return true;
    }).filter(message => {
        if (this.recipientId) {
            return (message.fromId === this.recipientId || message.sentToId === this.recipientId);
        }
        return true;
    });
}


    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
    
        switch (actionName) {
            case 'checkAttachments':
                this.selectedMessageId = row.messageId;
                this.checkAttachments();
                break;
            case 'openModal':
                this.selectedMessageId = row.messageId; // Set selected message ID
                this.selectedMessageContent = row.messageContent; // Set selected message content
                this.showModal = true; // Show modal
                this.toggleCheckbox(row.messageId);
                break;
            default:
                break;
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        if (selectedRows.length === 1) {
            const selectedMessage = selectedRows[0];
            this.selectedMessageId = selectedMessage.messageId;
            this.selectedMessageContent = selectedMessage.messageContent;
            this.messagefromName = selectedMessage.fromName;
            this.showModalopen = true;
        } else {
            this.selectedMessageId = null;
            this.selectedMessageContent = '';
        }
    }

    handleRowClick(event) {
        const row = event.detail.row;
        
        if (row) {
            const messageId = row.messageId;
            
            this.selectedMessageId = messageId;
            this.selectedMessageContent = row.messageContent;
            this.showModalopen = true;
        } 
    }


    checkAttachments() {
        getMessageAttachments({ messageId: this.selectedMessageId })
            .then(result => {
             
                if (result && Object.keys(result).length > 0) {
                    this.pdfAttachments = Object.keys(result).map(item => ({
                        label: result[item],
                        value: item,
                        url: `/sfc/servlet.shepherd/document/download/${item}`
                    }));
                    this.showModal = true;
                    this.attachmentsAvailable = true;
                } else {
                    this.clearForm();
                    this.showModal = true;
                    this.attachmentsAvailable = false;
                }
            })
            .catch(()=> {
                
                this.showModal = false;
            });
    }

    refreshMessages() {
        refreshApex(this.wiredMessagesResult);
    }

    closeModal() {
        this.showModal = false;
    }

    Modalclose() {
    this.showModalopen = false;
    this.selectedMessageId = null;
    this.selectedMessageContent = '';
    this.resetCheckbox();
    const dataTable = this.template.querySelector('lightning-datatable');
    if (dataTable) {
        dataTable.selectedRows = [];
    }
}

    clearForm() {
        this.pdfAttachments = [];
    }
    resetCheckbox() {
        this.selectedMessages = {}; // Reset selected messages
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

    // Function to convert Date object to formatted datetime string
    toDateTimeString(date) {
        if (!date) {
            return null; // Return null if date is null or empty
        }
        return new Date(date).toLocaleString(); // Convert date to locale string
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
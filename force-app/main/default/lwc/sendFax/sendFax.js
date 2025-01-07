import { LightningElement, wire, api } from "lwc";
import { getRecord } from "lightning/uiRecordApi";
import enrolleerecord from "@salesforce/apex/J_SendFaxLwc.getEnrolleeName";
import relatedFiles from "@salesforce/apex/J_SendFaxLwcHandler.getRelatedFiles";
import { NavigationMixin } from "lightning/navigation";
import getFaxNumber from "@salesforce/apex/J_SendFaxLwc.getFaxNum";
import getPharFax from "@salesforce/apex/J_SendFaxHandler.getPharFax";
import getRecFaxFiles from "@salesforce/apex/J_SendFaxLwcHandler.getRecFaxFiles";
import getCBenefitFiles from "@salesforce/apex/J_SendFaxLwcHandler.fetchCoverageBenefitFiles";
import getConsentFiles from "@salesforce/apex/J_SendFaxLwcHandler.fetchConsentRelatedFiles";
import saveFax from "@salesforce/apex/J_SendFaxLwcHandler.saveFax";
import getCpFaxNum from "@salesforce/apex/J_SendFaxLwc.getCpFaxNum";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
export default class SendFax extends NavigationMixin(LightningElement) {
  @api recordId;
  enrolleeName = null;
  selectedValue = "";
  inputValue;
  showInputBox = false;
  pharFax;
  faxNum;
  relatedFiles = null;
  getRecFaxFiles = null;
  getCBenefitFiles = null;
  getConsentFiles = null;
  cpFaxNum = null;
  selectedFileIds = [];
  showSpinner = false;
  @api objectApiName;
  objectApiReference;

  @wire(getRecord, { recordId: "$recordId", fields: [] })
  wiredRecord({ data, error }) {
    try {
      if (data) {
        this.objectApiReference = data.apiName;
      } else if (error) {
        throw new Error(error.body.message); // Throwing the error to be caught below
      }
    } catch (err) {
      this.showToast("Error fetching CP Fax Number:", err.message, "error");
    }
  }

  get isCareProgramEnrollee() {
    const result = this.objectApiReference === "CareProgramEnrollee";
    return result;
  }

  @wire(getCpFaxNum, { recordId: "$recordId" })
  wiredCpFaxNum({ data, error }) {
    try {
      if (data !== null && data !== undefined) {
        this.cpFaxNum = data;
      } else if (error) {
        throw new Error(error.body.message); // Throwing the error to be caught below
      }
    } catch (err) {
      this.showToast("Error fetching CP Fax Number:", err.message, "error");
    }
  }

  @wire(getRecFaxFiles, { recordId: "$recordId" })
  wiredgetRecFaxFiles({ data, error }) {
    try {
      if (data !== null && data !== undefined && data.length > 0) {
        this.getRecFaxFiles = data;
      } else if (error) {
        throw new Error(error.body.message); // Throwing the error to be caught below
      }
    } catch (err) {
      this.showToast("Error fetching Fax Files:", err.message, "error");
    }
  }

  @wire(relatedFiles, { recordId: "$recordId" })
  wiredRelatedFiles({ data, error }) {
    try {
      if (data !== null && data !== undefined && data.length > 0) {
        this.relatedFiles = data;
      } else if (error) {
        throw new Error(error.body.message); // Throwing error to be caught below
      }
    } catch (err) {
      this.showToast("Error fetching Related Files:", err.message, "error");
    }
  }

  @wire(getCBenefitFiles, { recordId: "$recordId" })
  wiredgetCBenefitFiles({ data, error }) {
    try {
      if (data !== null && data !== undefined && data.length > 0) {
        this.getCBenefitFiles = data;
      } else if (error) {
        throw new Error(error.body.message); // Throwing the error to be caught below
      }
    } catch (err) {
      this.showToast(
        "Error fetching Coverage benefit Fax Files:",
        err.message,
        "error"
      );
    }
  }

  @wire(getConsentFiles, { recordId: "$recordId" })
  wiredgetConsentFiles({ data, error }) {
    try {
      if (data !== null && data !== undefined && data.length > 0) {
        this.getConsentFiles = data;
      } else if (error) {
        throw new Error(error.body.message); // Throwing the error to be caught below
      }
    } catch (err) {
      this.showToast("Error fetching Consent Files:", err.message, "error");
    }
  }

  connectedCallback() {
    // Assign apivalue to objectApiReference
    this.objectApiReference = this.objectApiName;
  }

  get isInputValueNull() {
    return !this.inputValue || this.inputValue.trim() === "";
  }

  handleChange(event) {
    this.selectedValue = event.detail.value;

    // Check if "Pharmacy" is selected
    if (this.selectedValue === "pharmacy") {
      // Call the Apex method to get the fax number
      this.retrievePharFax();
      this.selectedValue = event.detail.value;
      this.showInputBox = this.selectedValue === "pharmacy";
    } else if (this.selectedValue === "provider") {
      this.selectedValue = event.detail.value;
      // Call the Apex method to get the fax number
      this.retrieveProviderFaxNumber();
      this.showInputBox = this.selectedValue === "provider";
    } else if (this.selectedValue === "other") {
      this.showInputBox = true;
      this.inputValue = null;
    } else {
      // For "other" option, set the manually entered value to inputValue
      this.showInputBox = false;
    }
  }

  handleInputChange(event) {
    // Update the inputValue property with the new value from the event
    this.inputValue = event.target.value;
  }

  retrievePharFax() {
    getPharFax({ recordId: this.recordId })
      .then((result) => {
        // Handle the result, which could be the pharmacy fax number
        this.pharFax = result;
        this.inputValue = this.pharFax;
      })
      .catch((error) => {
        this.showToast("Error", error.body.message, "error");
      });
  }

  retrieveProviderFaxNumber() {
    getFaxNumber({ recordId: this.recordId })
      .then((result) => {
        // Handle the result, which could be the provider fax number
        this.faxNum = result;
        this.inputValue = this.faxNum;
      })
      .catch((error) => {
        this.showToast("Error", error.body.message, "error");
      });
  }

  @wire(enrolleerecord, { recordId: "$recordId" })
  wiredEnrolleeRecord({ data, error }) {
    if (data !== null && data !== undefined) {
      this.enrolleeName = data;
    } else if (error) {
      this.showToast(
        "Error fetching enrollee record:",
        error.body.message,
        "error"
      );
    }
  }

  value = "--Please Select--";

  get options() {
    return [
      { label: "Provider", value: "provider" },
      { label: "Pharmacy", value: "pharmacy" },
      { label: "Other", value: "other" }
    ];
  }

  handleFileSelectionCommon(event, selectedFileIds) {
    const contentDocumentId = event.target.dataset.fileid;
    if (event.target.checked) {
      selectedFileIds.push(contentDocumentId);
    } else {
      const index = selectedFileIds.indexOf(contentDocumentId);
      if (index !== -1) {
        selectedFileIds.splice(index, 1);
      }
    }
  }

  handleFileSelection(event) {
    this.handleFileSelectionCommon(event, this.selectedFileIds);
  }

  handleFileSelectionFax(event) {
    this.handleFileSelectionCommon(event, this.selectedFileIds);
  }

  openFileInNewTab(event) {
    event.preventDefault();
    const contentDocumentId = event.target.dataset.fileid;
    let globalthis = window;
    // Check if contentDocumentId is valid and open in a new tab
    if (contentDocumentId) {
      const fileUrl = `/lightning/r/ContentDocument/${contentDocumentId}/view`;
      globalthis.open(fileUrl, "_blank");
    }
  }

  handleSendClick() {
    // Ensure that the data is properly updated using @track
    this.selectedValue = this.selectedValue || "";
    this.inputValue = this.inputValue || "";
    this.pharFax = this.pharFax || "";
    this.faxNum = this.faxNum || "";

    if (!this.selectedFileIds || this.selectedFileIds.length === 0) {
      this.showToast("Error", "Please select at least one file.", "error");

      return;
    }

    // Check for required fields
    if (!this.selectedValue || !this.inputValue) {
      this.showToast("Error", "Recipient Fax Number Missing.", "error");

      return;
    }

    // Show the spinner
    this.showSpinner = true;

    if (this.selectedValue && this.selectedFileIds.length > 0) {
      let faxNumber;

      if (this.selectedValue === "pharmacy") {
        faxNumber = this.pharFax;
      } else if (this.selectedValue === "provider") {
        faxNumber = this.faxNum;
      } else if (this.selectedValue === "other") {
        faxNumber = this.inputValue;
      } else {
        return;
      }

      // Get the current date and time
      const currentDateTime = new Date().toISOString();

      const faxDetails = {
        selectedFiles: this.selectedFileIds,
        recordId: this.recordId,
        sendDateTime: currentDateTime,
        deliveryDateTime: currentDateTime,
        to: this.selectedValue
      };
      // Call the Apex method to save the data
      saveFax({
        faxDetails: faxDetails,
        faxNumber: faxNumber,
        orgFaxNum: this.cpFaxNum
      })
        .then((result) => {
          if (result.startsWith("Error")) {
            this.showToast(
              "Error",
              "Failed to send the fax. Please try again.",
              "error"
            );
          } else {
            // Handle the success case

            // Navigate back to the record detail page
            this[NavigationMixin.Navigate]({
              type: "standard__recordPage",
              attributes: {
                recordId: this.recordId,
                objectApiName: "CareProgramEnrollee",
                actionName: "view"
              }
            });

            this.showToast(
              "Success",
              "Fax has been sent successfully.",
              "success"
            );
            // Close the LWC by refreshing the entire page
            if (typeof window !== "undefined") {
              window.location.reload();
            }
          }

          // Hide the spinner after the action is completed
          this.showSpinner = false;
        })
        .catch((error) => {
          this.showToast(
            "Error Failed to send the fax. Please try again.",
            error.body.message,
            "error"
          );
        });
    }
  }
  showToast(title, message, variant) {
    if (!import.meta.env.SSR) {
      const event = new ShowToastEvent({
        title: title, // Title of the toast
        message: message, // Content of the toast
        variant: variant, // Variant determines the appearance (success, warning, error, info)
        mode: "dismissable" // Allow the user to dismiss the toast
      });

      // Dispatch the toast event to display it
      this.dispatchEvent(event);
    }
  }
}
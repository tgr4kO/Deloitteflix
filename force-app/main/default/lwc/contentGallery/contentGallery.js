import { LightningElement, api, wire } from 'lwc';
import getContentByClient from '@salesforce/apex/ContentSelector.getContentByClient';

export default class ContentGallery extends LightningElement {
    @api recordId; // Id del Account en la record page
    content;       // será una LISTA de Content__c

    @wire(getContentByClient, { accId: '$recordId' })
    wiredContent({ error, data }) {
        if (data) {
            this.content = data;
            console.log('Contenido:', data);
        } else if (error) {
            console.error('Error fetching content:', error);
        }
    }

    handleClick(event) {
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: event.detail
            })
        );
    }
}
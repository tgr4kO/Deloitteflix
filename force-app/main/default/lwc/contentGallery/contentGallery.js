import { LightningElement, api, wire } from 'lwc';
import getContentByClient from '@salesforce/apex/ContentSelector.getContentByClient';

export default class ContentGallery extends LightningElement {
    @api recordId; // Id del Account en la record page

    content = []; // LISTA de Content__c

    @wire(getContentByClient, { accId: '$recordId' })
    wiredContent({ error, data }) {
        if (data) {
            this.content = data;
            console.log('📦 Contenido cargado:', JSON.parse(JSON.stringify(data)));
        } else if (error) {
            console.error('❌ Error fetching content:', error);
        }
    }

    /* =========================
       GETTERS DE SECCIONES
       ========================= */

    // SERIES
    get seriesContent() {
        return this.content.filter(
            item => item.Content_type__c === 'Serie'
        );
    }

    // MOVIES + DOCUMENTARIES
    get moviesAndDocs() {
        return this.content.filter(
            item =>
                item.Content_type__c === 'Movie' ||
                item.Content_type__c === 'Documentary'
        );
    }

    // Flags para mostrar / ocultar secciones
    get hasSeries() {
        return this.seriesContent.length > 0;
    }

    get hasMoviesOrDocs() {
        return this.moviesAndDocs.length > 0;
    }

    // Contador total (por si lo usas)
    get contentCount() {
        return this.content.length;
    }
    get seriesCount() {
    return this.seriesContent.length;
    }

    get moviesAndDocsCount() {
        return this.moviesAndDocs.length;
    }

    /* =========================
       EVENTOS
       ========================= */

    handleSelect(event) {
        this.dispatchEvent(
            new CustomEvent('select', {
                detail: event.detail
            })
        );
    }
}
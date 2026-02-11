import { LightningElement, track } from 'lwc';
import search from '@salesforce/apex/OMDBLwcController.search';
import getDetail from '@salesforce/apex/OMDBLwcController.getDetail';
import downloadToDb from '@salesforce/apex/OMDBLwcController.downloadToDb';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class Omdb_parent extends LightningElement {
    @track results = [];
    @track selectedItem;

    isLoading = false;
    view = 'search'; // 'search' o 'detail'

    get isSearchView() {
        return this.view === 'search';
    }

    get isDetailView() {
        return this.view === 'detail';
    }

    handleSearchChange(event) {
        const query = event.detail.query;

        this.isLoading = true;
        this.view = 'search';
        this.results = [];
        this.selectedItem = undefined;

        search({ searchText: query })
            .then((data) => {
                console.log('OMDB data ==> ', JSON.parse(JSON.stringify(data)));
                this.results = data || [];
            })
            .catch((error) => {
                this.showToast('Error', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleRowDetail(event) {
        const imdbId = event.detail.imdbId;
        this.fetchDetail(imdbId);
    }

    fetchDetail(imdbId) {
        this.isLoading = true;
        this.view = 'detail';
        this.selectedItem = undefined;

        getDetail({ imdbId })
            .then((data) => {
                this.selectedItem = data;
            })
            .catch((error) => {
                this.showToast('Error', this.reduceError(error), 'error');
                this.view = 'search';
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    handleBackFromDetail() {
        this.view = 'search';
        this.selectedItem = undefined;
    }

    handleDownload(event) {
        const imdbId = event.detail.imdbId;
        this.isLoading = true;

        downloadToDb({ imdbId })
            .then((record) => {
                this.showToast(
                    'Success',
                    `Content "${record.Name}" saved in Salesforce.`,
                    'success'
                );
            })
            .catch((error) => {
                this.showToast('Error', this.reduceError(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }

    reduceError(error) {
        if (Array.isArray(error?.body)) {
            return error.body.map((e) => e.message).join(', ');
        } else if (typeof error?.body?.message === 'string') {
            return error.body.message;
        }
        return 'Unknown error';
    }
}
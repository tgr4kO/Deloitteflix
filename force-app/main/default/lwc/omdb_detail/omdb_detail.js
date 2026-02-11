import { LightningElement, api } from 'lwc';

export default class Omdb_detail extends LightningElement {
    @api item; // OMDbResponse

    get title() {
        return this.item?.title;
    }
    get year() {
        return this.item?.year;
    }
    get genre() {
        return this.item?.genre;
    }
    get imdbRating() {
        return this.item?.imdbRating;
    }
    get plot() {
        return this.item?.plot;
    }
    get poster() {
        return this.item?.poster;
    }
    get imdbId() {
        return this.item?.imdbID;
    }

    handleBack() {
        this.dispatchEvent(new CustomEvent('back'));
    }

    handleDownload() {
        if (this.imdbId) {
            this.dispatchEvent(
                new CustomEvent('download', {
                    detail: { imdbId: this.imdbId }
                })
            );
        }
    }
}
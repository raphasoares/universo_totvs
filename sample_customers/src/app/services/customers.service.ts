import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';

@Injectable({
  providedIn: 'root'
})
export class CustomersService {
  public url = `/api/cst/v1/customers`;

  constructor(private httpClient: HttpClient) { }

  public getCustomers(params?: any): Observable<unknown> {
    let url_customer;
    url_customer = this.url;

    if (params.page) {
      url_customer = this.url + '?page=' + params.page;
    }

    return this.httpClient.get(url_customer).pipe();
  }

  public getCustomer(custNum: Number): Observable<unknown> {
    let url_customer;
    url_customer = this.url + '/' + custNum;

    return this.httpClient.get(url_customer).pipe();
  }

  public removeCustomer(custNum: Number): Observable<unknown> {
    let url_customer;
    url_customer = `${this.url}/${custNum}`;

    return this.httpClient.delete(url_customer).pipe();
  }

  public updateCustomer(custNum: Number, customer): Observable<unknown> {
    let url_customer;
    url_customer = `${this.url}/${custNum}`;

    return this.httpClient.put(url_customer, customer).pipe();
  }

  public createCustomer(customer): Observable<unknown> {
    return this.httpClient.post(this.url, customer).pipe();
  }
}

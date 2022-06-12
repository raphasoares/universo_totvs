import { Component, OnInit } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { PoNotificationService } from '@po-ui/ng-components';
import { Customer } from 'src/app/models/customer';
import { CustomersService } from 'src/app/services/customers.service';

@Component({
  selector: 'app-customer-form',
  templateUrl: './customer-form.component.html',
  styleUrls: ['./customer-form.component.css']
})
export class CustomerFormComponent implements OnInit {
  public customer: Customer = new Customer();
  private action;
  constructor(
    private customersService: CustomersService,
    private notificationService: PoNotificationService,
    private router: Router,
    private route: ActivatedRoute) { }

  ngOnInit(): void {
    this.route.params.subscribe(params => {
      if (params['id']) {
        this.loadData(params['id']);
        this.action = 'update';
      }
    });
  }

  public save() {
    const customer = {...this.customer};
    if (this.action === 'update') {
      this.customersService.updateCustomer(this.customer['Cust-Num'], customer).subscribe(data => {
        this.notificationService.success('Cliente atualizado com sucesso');
        this.router.navigateByUrl('/');
      })
    }
    else {
      this.customersService.createCustomer(this.customer).subscribe(data => {
        this.notificationService.success('Cliente cadastrado com sucesso');
        this.router.navigateByUrl('/');
      });
    }
  }

  public cancel() {
    this.router.navigateByUrl('/');
  }

  private loadData(custNum) {
    let customer;
    this.customersService.getCustomer(custNum).subscribe(data => {
      customer = data;

      this.customer = customer;
    })
  }
}

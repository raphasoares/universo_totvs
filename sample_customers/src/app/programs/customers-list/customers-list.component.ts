import { Component, OnInit } from '@angular/core';
import { Router } from '@angular/router';
import { PoNotificationService, PoPageAction, PoTableAction, PoTableColumn } from '@po-ui/ng-components';
import { Customer } from 'src/app/models/customer';
import { CustomersService } from 'src/app/services/customers.service';

@Component({
  selector: 'app-customers-list',
  templateUrl: './customers-list.component.html',
  styleUrls: ['./customers-list.component.css']
})
export class CustomersListComponent implements OnInit {
  private page: number = 1;
  public columns: Array<PoTableColumn>;
  public customers: Array<Customer>;
  public hasNext: boolean = false;
  public tableActions: Array<PoTableAction>;
  public actions: Array<PoPageAction>;

  constructor(
    private customerService: CustomersService,
    private poNotification: PoNotificationService,
    private router: Router) { }

  ngOnInit(): void {
    this.initializeTableColumns();
    this.initializeTableActions();
    this.initializePageActions();
    this.loadData();
  }

  private initializeTableColumns() {
    this.columns = [
      {
        property: 'Cust-Num',
        label: 'Número'
      },
      {
        property: 'Name',
        label: 'Nome'
      },
      {
        property: 'Sales-Rep',
        label: 'Representante'
      },
      {
        property: 'Contact',
        label: 'Contato'
      },
      {
        property: 'Credit-Limit',
        label: 'Limite de crédito'
      }
    ]
  }

  private initializeTableActions() {
    this.tableActions = [
      {
        action: this.onEditCustomer.bind(this),
        label: 'Editar'
      },
      {
        action: this.onRemoveCustomer.bind(this),
        label: 'Remover'
      }
    ]
  }

  private initializePageActions() {
    this.actions = [
      { action: this.onNewCustomer.bind(this), label: 'Cadastrar', icon: 'thf-icon-user-add' }
    ]
  }

  private loadData(params: { page?: number, search?: string } = { }) {
    this.customerService.getCustomers(params).subscribe(response => {
      this.customers = !params.page || params.page === 1 ? response['items'] : [...this.customers, ...response['items']];
      this.hasNext = response['hasNext'];
    })
  }

  public showMore() {
    let params: any = {
      page: ++this.page
    };

    this.loadData(params);
  }

  private onNewCustomer(customer) {
    this.router.navigateByUrl('/new');
  }

  private onEditCustomer(customer) {
    this.router.navigateByUrl(`/edit/${customer['Cust-Num']}`);
  }

  private onRemoveCustomer(customer) {
    this.customerService.removeCustomer(customer['Cust-Num']).subscribe(response => {
      this.poNotification.warning('Cliente apagado com sucesso');
      this.customers.splice(this.customers.indexOf(customer), 1);
    })
  }

}

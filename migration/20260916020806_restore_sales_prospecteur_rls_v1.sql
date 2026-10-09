begin;

create policy sales_prospecteur_select on public.sales
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sales_prospecteur_insert on public.sales
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sales_prospecteur_update on public.sales
  for update to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  )
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = sales.prospecteur_id
        and p.organization_id = sales.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sale_items_prospecteur_select on public.sale_items
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sale_items_prospecteur_insert on public.sale_items
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy sale_items_prospecteur_update on public.sale_items
  for update to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  )
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.sales s
      join public.prospecteurs p on p.id = s.prospecteur_id
      where s.id = sale_items.sale_id
        and s.organization_id = sale_items.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy payments_prospecteur_select on public.payments
  for select to authenticated
  using (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = payments.prospecteur_id
        and p.organization_id = payments.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

create policy payments_prospecteur_insert on public.payments
  for insert to authenticated
  with check (
    private.is_prospecteur(organization_id)
    and exists (
      select 1 from public.prospecteurs p
      where p.id = payments.prospecteur_id
        and p.organization_id = payments.organization_id
        and p.user_id = auth.uid()
        and p.status = 'active'
    )
  );

commit;

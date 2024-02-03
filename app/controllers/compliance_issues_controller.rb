class ComplianceIssuesController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  # GET /compliance_issues?property_id={property_id}&date={date}
  # GET /compliance_issues.json?property_id={property_id}&date={date}
  def show
    @property_id = params[:property_id]
    @date = params[:date]
    @property = Property.find(@property_id)
    @property_name = @property.full_name
    if @property_name.nil?
      @property_name = @property.code
    end

    respond_to do |format|
      format.html
      format.json do 
        render_datatables
      end
    end

  end
  
  private
  def render_datatables
    
    @compliance_issues = ComplianceIssue.where(property: @property, date: @date, trm_notify_only: false).order("issue ASC")
    
    data_tables = create_data_tables
    render json: data_tables.as_json
  end
  
  def create_data_tables
    data_tables = {
         data: create_table_data
       }
       
    return data_tables    
  end
  
  def create_table_data
    table_data = @compliance_issues.collect do |ci|
      culprits_html = ''
      issue_html = ci.issue
      training_pdf = get_training_pdf(ci.issue)
      if training_pdf != ""
        issue_html = "<a href=\"/#{training_pdf}\" target=\"_blank\">#{ci.issue}</a>"
      end
      # separate all culprits
      culprits = ci.culprits.split(';')
      culprits.each do |i|
        culprits_html += "<tr><td>" + i + " (#{find_consecutive_days_for_culprit(i)})" + "</td></tr>"
      end

      [
        "<input class='compliance_issue_id' type='hidden' value='#{ci.id}'><span>#{issue_html}</span>",
        "<span>#{number(ci.num_of_culprits)}</span>",
        "<span><table>#{culprits_html}</table></span>"
      ]
    end    
    
    return table_data
  end

  def find_consecutive_days_for_issue(issue)
    result = ActiveRecord::Base.connection.exec_query("
    SELECT count(*) FROM (
      SELECT * FROM (
        SELECT date, issue, date - lag(date, 1) OVER w delta, date-first_value(date) OVER w total, count(*) OVER w c 
        FROM compliance_issues WHERE date <= DATE '#{@date}' AND property_id = #{@property_id} AND issue = '#{issue}' 
        WINDOW w AS (ORDER BY date DESC) 
        ORDER BY date DESC)
      compliance_issues WHERE c - ABS(total) = 1)
    compliance_issues;")

    result.to_a[0]['count']
  end

  def find_consecutive_days_for_culprit(culprit)
    result = ActiveRecord::Base.connection.exec_query("
    SELECT count(*) FROM (
      SELECT * FROM (
        SELECT date, culprits, date - lag(date, 1) OVER w delta, date-first_value(date) OVER w total, count(*) OVER w c 
        FROM compliance_issues WHERE date <= DATE '#{@date}' AND property_id = #{@property_id} AND culprits LIKE '%#{culprit}%' 
        WINDOW w AS (ORDER BY date DESC) 
        ORDER BY date DESC)
      compliance_issues WHERE c - ABS(total) = 1)
    compliance_issues;")

    result.to_a[0]['count']
  end

  def get_training_pdf(issue)
    case issue
    when "Past Move In Date"
      return "redbot_training_PAST_DUE_MOVE_IN.pdf"
    when "Bad Debt Writeoff Past Due"
      return "redbot_training_BAD_DEBT.pdf"
    when "Partial Payments (over $100)"
      return "redbot_training_PARTIAL_PAYMENTS.pdf"
    when "Unit Vacant Over 60 Days"
      return "redbot_training_VACANT_60_DAY.pdf"
    when "Deposit Accounting Past Due"
      return "redbot_training_DEPOSIT_ACCOUNTING.pdf"
    when "Eviction Past Due"
      return "redbot_training_FILING_EVICTIONS.pdf"
    when "Past Move Out Date"
      return "redbot_training_PAST_DUE_MOVE_OUT.pdf"
    when "Market Survey Past Due"
      return "redbot_training_MARKET_SURVEY_PAST_DUE.pdf"
    when "Security Deposit Not Collected for Approved Applicant"
      return "redbot_training_SECURITY_DEPOSIT_NOT_COLLECTED.pdf"      
    when "IR Needs Attention"
      return "redbot_training_IR_NEEDS_ATTENTION.pdf" 
    when "Latest Product Inspection Over 2 Weeks Old"
      return "redbot_training_PRODUCT_INSPECTION_NEEDED.pdf" 
    when "PO > 45 Days Not Closed or Invoiced"
      return "redbot_training_PO_NOT_INVOICED.pdf" 
    when "Eviction Fees Not Charged"
      return "redbot_training_EVICTION_FEES_NOT_CHARGED.pdf" 
    when "Termination Fees Not Charged"
      return "redbot_training_EARLY_TERM_FEES_NOT_CHARGED.pdf"
    when "Sec Dep Check Not Issued"
      return "redbot_training_SECURITY_DEPOSIT_NOT_REFUNDED.pdf"
    when "Bad Debt Not Sent to Collections"
      return "redbot_training_ACCTS_NOT_SENT_TO_COLLECTIONS.pdf"
    when "Deposit Accounting Workflow Approval Past Due"
      return "redbot_training_DEPOSIT_ACCOUNTING_WORKFLOW_APPROVAL_PAST_DUE.pdf"
    when "Work Order > 48 Hours with No Reason"
      return "redbot_training_WORK_ORDER_WITH_NO_REASON_INCOMPLETE.pdf"
    when "Employee Reimbursement PO Needs Reconciliation"
      return "redbot_training_EMPLOYEE_REIMBURSEMENT_PO_NEEDS_RECONCILIATION.pdf"
    when "Payment Plan / Promise to Pay Delinquent"
      return "redbot_training_PAYMENT_PLAN_PROMISE_TO_PAY_DELINQUENT.pdf"
    when "Employee Lease with Delinquent Balance"
      return "redbot_training_EMPLOYEE_LEASE_WITH_DELINQUENT_BALANCE.pdf"
    when "MTM > 5% of Your Unit Count"
      return "redbot_training_MONTH_TO_MONTH_COUNT_EXCEEDS_5_OF_UNIT_COUNT.pdf"
    when "NSF Since Sec Dep Accounting"
      return "redbot_training_NSF_SINCE_SEC_DEP_ACCOUNTING.pdf"
    else
      return ""
    end
  end
  
  def number(value)
    number_with_precision(value, precision: 0, strip_insignificant_zeros: true)  
  end

end

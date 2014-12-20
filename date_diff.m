function out=date_diff(date1, date2)
%return date2-date1 in months and days
M=months(date1,date2);
D=date2-addtodate(date1, M, 'month');
out=[M D];
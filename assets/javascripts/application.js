var K3nInvoiceRoundupSpentTime = function () {
	var shortLanguage = 'en';
	var language = 'en-GB';
	var ajax = false;

	function setLanguage(language){
		switch(language) {
			case 'de':
				this.language = 'de-DE';
				break;
			default:
				this.language = 'en-GB';
		}
		this.shortLanguage = language;
	}

	function setPlugin(plugin){
		this.plugin = plugin
	}

	function setLang(lang){
		if (this.lang === undefined || this.lang === null) {
			this.lang = ['k3n_invoice_roundup_spent_time'];
		}
		this.lang['k3n_invoice_roundup_spent_time'] = lang
	}
	
	function setUserId(user){
		this.user_id = user;
		stateKey = 'k3n_invoice_roundup_spent_time/' + this.user_id;
	}

	function setApiKey(key){
		this.api_key = key;
	}

	function setApiUrl(url){
		this.timelog_url = url;
	}

	function t(key, props) {
		return (this.lang['k3n_invoice_roundup_spent_time'][key] || key).replace(/%{([^}]+)}/g, function (_, prop) {
			return String(Object(props)[prop]);
		});
	}

	function padLeft(num, size) {
		var s = num + "";
		while (s.length < size) s = "0" + s;
		return s;
	}

	function addTime(t1, t2){
		var result = [];
		var tt1 = t1.split(':');
		var tt2 = t2.split(':');
		var mt1 = Number(tt1[0]) * 60 + Number(tt1[1]);
		var mt2 = (t2.charAt(0) == '-' ? -1 : 1) * (Number(tt2[0]) * 60 + Number(tt2[1]));
		var diff = 0;  
		diff = mt1 + mt2;
		result[0] = Math.abs(Math.floor(parseInt(diff / 60)));
		result[1] = padLeft(Math.abs(diff % 60), 2);
		return result.join(':');
	}

	function parseTime(time) {
		var parsed = /^(\d*(\.\d+)?)$|^((\d+)[:h])?((\d+)m?)?$/.exec(time);
		return parsed && parsed[1] ? parseFloat(parsed[1]) :
			   parsed ? parseInt(parsed[4] || 0) + parseInt((parsed[5] ? parsed[5].substring(0, 2) : 0) || 0) / 60 :
			   null;
	}

	function convertToTimeString(time) {
		const hours = Math.floor(time / 60);  
		const minutes = pad(Math.ceil(time % 60), 2);
		return `${hours}:${minutes}`;         
	}

	function convertToTimeInt(time) {
		const hours = parseInt(time);
		const minutes = pad(Math.round(((time - hours) * 60 / 100) * 100), 2);
		return `${hours}:${minutes}`;
	}

	function pad(n, width, z) {
		z = z || '0';
		n = n + '';
		return n.length >= width ? n : new Array(width - n.length + 1).join(z) + n;
	}

	function init(){
		this.ajax = false;
		var $object = this;
		$( document ).ready(function() {
			$('table.list.time-entries tr.time-entry td.invoice_hours').dblclick(function(){
				if($(this).parent().find('td.buttons > a.icon-edit').length > 0){
					if (!$object.api_key) {
						alert(t('need_rest_api'));
					} else {
						if($(this).find('span.edit-time-entry-ajax').length == 0){
							var $oldValue = $(this).text();
							$(this).attr('data-value', $oldValue);
							$(this).html('').append(
								$('<span class="edit-time-entry-ajax" />').append(
									$('<input class="edit-time-entry-ajax-input" type="text" size="4" />')
									.val($oldValue)
									.change(function () {
										//$(this).trigger('ajax:update');
									})
									.bind("keypress", function(event) {
										if (event.keyCode === 13) {
											$(this).trigger('ajax:update');
											event.preventDefault();
											return false;
										}
									})
									.on('ajax:update', function(){
										if($object.ajax == false && parseTime($(this).val())){
											$item = $(this);
											$(this).parent().find('i.fa.fa-check').removeClass('fa-check').addClass('fa-spinner fa-spin');
											var $url = $(this).parent().parent().parent().find('td.buttons > a.icon-del').attr('href') + ".json";
											var $val = $(this).val();
											var $id = $(this).closest('tr').attr('id').replace('time-entry-', '');
											$object.ajax = true;
											$.ajax(
												$object.timelog_url.replace('XXX', $id), 
												{
													method: 'PUT',
													data: JSON.stringify({
														total_invoice_hours: (($('#main p.query-totals > span.total-for-invoice-hours > span.value').length > 0) ? $('#main p.query-totals > span.total-for-invoice-hours > span.value').text() : 0),
														time_entry: {
															invoice_hours: $val
														}
													}),
													contentType: 'application/json',
													headers: {
														'X-Redmine-API-Key': $object.api_key,
													}
												}
											)
											.done(function (response) {
												if(response.hasOwnProperty('time_entry')){
													if($('tr#time-entry-' + response.time_entry.id).prevAll('tr.group:first').find('span.total-for-invoice-hours > span.value').length > 0){
														$groupTotalVal = $('tr#time-entry-' + response.time_entry.id).prevAll('tr.group:first').find('span.total-for-invoice-hours > span.value').text();
														if($groupTotalVal.indexOf(':') != -1){
															$('tr#time-entry-' + response.time_entry.id).prevAll('tr.group:first').find('span.total-for-invoice-hours > span.value').text(addTime($groupTotalVal, response.invoice_hours_diff));
														} else {
															$('tr#time-entry-' + response.time_entry.id).prevAll('tr.group:first').find('span.total-for-invoice-hours > span.value').text(parseFloat($groupTotalVal) + parseFloat(response.invoice_hours_diff));
														}
													}
													$('tr#time-entry-' + response.time_entry.id).find('span.edit-time-entry-ajax').remove();
													$('tr#time-entry-' + response.time_entry.id).find('td.invoice_hours').html(response.invoice_hours).attr('data-value', response.invoice_hours);
													if($('#main p.query-totals > span.total-for-invoice-hours > span.value').length > 0){
														$('#main p.query-totals > span.total-for-invoice-hours > span.value').text(response.total_invoice_hours);
													}
												}											
												$object.ajax = false;
											})
											.fail(function ($xhr) {
												$item.parent().parent().html($item.parent().parent().attr('data-value'));
												var alertText = '';
												if($xhr.responseJSON.errors){
													$xhr.responseJSON.errors.forEach(function(element) {
														alertText += element + "\n";
													});
													alert(alertText);
												}
												$object.ajax = false;
											});
											
										}
									}),
									$('<i class="fa fa-check"></i></span>').click(function(){
										$(this).parent().find('input.edit-time-entry-ajax-input').trigger('ajax:update');
									}),
									$('<i class="fa fa-ban"></i></span>').click(function(){
										var $td = $(this).parent().parent();
										$td.html($td.attr('data-value'));									
									})
								)
							);
						}
					}
				}
			});
			$('table.list.time-entries tr.time-entry td.comments').dblclick(function(){
				if($(this).parent().find('td.buttons > a.icon-edit').length > 0){
					if (!$object.api_key) {
						alert(t('need_rest_api'));
					} else {
						//var $entryTime = $(this).parent().find('.hours').text();
						var $entryInvoiceTime = $(this).parent().find('.invoice_hours').text();

						$id = parseInt($(this).parent().attr('id').replace('time-entry-', ''));
						$.ajax(
							'/time_entries/' + $id + '.json', 
							{
								method: 'GET',
								contentType: 'application/json',
								headers: {
									'X-Redmine-API-Key': $object.api_key,
								}
							}
						)
						.done(function (response) {
							var $entryInternCommentLabel = '';
							var $entryInternCommentValue = '';

							jQuery.each(response.time_entry.custom_fields, function(i, val) {
								if(val.id == 40){
									$entryInternCommentLabel = val.name;
									$entryInternCommentValue = val.value;
								}
							});

							var spentTimeCommentDialog   = null;
							if (spentTimeCommentDialog) {
								spentTimeCommentDialog.dialog('destroy');
							}
							var form       = $('<form class="spent_time_comment_form"/>').submit(false);
							[
								$('<fieldset/>').append($('<legend/>').text(t('details'))).append(
									$('<table width="100%"/>').append(
										$('<tr/>').append($('<td class="label_column"/>').text(t('field_hours')), $('<td/>').append(
											$('<input size="6" type="text" name="time_entry[hours]" id="time_entry_hours" />').val(convertToTimeInt(response.time_entry.hours)).change(function(){
												var hours = parseTime(form.find('#time_entry_hours').val());
												var invoice_hours = parseTime(form.find('#time_entry_invoice_hours').val());
												var min_invoice_hours = Math.ceil(hours * 4) / 4;
												if($('#time-entry-' + $id).find('td.hours').length > 0){
													if($('#time-entry-' + $id).find('td.hours').text().indexOf(':') != -1){
														form.find('#time_entry_hours').val(convertToTimeString(hours * 60));
														if(invoice_hours < min_invoice_hours){
															form.find('#time_entry_invoice_hours').val(convertToTimeString(min_invoice_hours * 60));
														}
													} else {
														form.find('#time_entry_hours').val(hours);
														if(invoice_hours < min_invoice_hours){
															form.find('#time_entry_invoice_hours').val(min_invoice_hours);
														}
													}
												} else {
													form.find('#time_entry_hours').val(convertToTimeString(hours * 60));
													if(invoice_hours < min_invoice_hours){
														form.find('#time_entry_invoice_hours').val(convertToTimeString(min_invoice_hours * 60));
													}
												}
											})
										)),
										$('<tr/>').append($('<td class="label_column"/>').text(t('field_invoice_hours')), $('<td/>').append(
											$('<input size="6" type="text" name="time_entry[invoice_hours]" id="time_entry_invoice_hours" />').val(convertToTimeInt(response.time_entry.invoice_hours)).change(function(){
												var hours = parseTime(form.find('#time_entry_hours').val());
												var invoice_hours = parseTime($(this).val());
												var invoice_hours_val = Math.ceil(invoice_hours * 4) / 4;
												var min_invoice_hours = Math.ceil(hours * 4) / 4;
												if($('#time-entry-' + $id).find('td.hours').length > 0){
													if($('#time-entry-' + $id).find('td.hours').text().indexOf(':') != -1){
														invoice_hours_val = convertToTimeString(invoice_hours_val * 60);
														if(invoice_hours < min_invoice_hours){
															invoice_hours_val = convertToTimeString(min_invoice_hours * 60);
														}
													} else {
														if(invoice_hours < min_invoice_hours){
															invoice_hours_val = min_invoice_hours;
														}
													}
												} else {
													invoice_hours_val = convertToTimeString(invoice_hours_val * 60);
													if(invoice_hours < min_invoice_hours){
														invoice_hours_val = convertToTimeString(min_invoice_hours * 60);
													}
												}
												form.find('#time_entry_invoice_hours').val(invoice_hours_val);
											})
										)),
										$('<tr/>').append($('<td class="label_column"/>').text(t('field_comments')), $('<td/>').append(
											$('<textarea id="time_entry_comment" name="time_entry[comments]" autocomplete="off" autofocus rows="4">' + response.time_entry.comments + '</textarea>')
										)),
										$('<tr/>').append($('<td class="label_column"/>').text($entryInternCommentLabel), $('<td/>').append(
											$('<textarea id="time_entry_intern_comment" name="time_entry[custom_field_values][40]" autocomplete="off" autofocus rows="4">' + $entryInternCommentValue + '</textarea>')
										))
									)
								)
							].forEach(function (elem) {
								form.append(elem);
							});
							spentTimeCommentDialog = form.dialog({
								dialogClass: 'spent_time_comment_dialog',
								position: { my: "center", at: "center", of: window },
								width: 450,
								draggable: false,
								modal: true,
								hide: 200,
								show: 200,
								title: t('comment_dialog_title'),
								open: function () { // Hack to remove black line in Safari
									if (/Apple/.test(window.navigator.vendor)) {
										$('.spent_time_comment_dialog').each(function (idx, elem) {
											elem.style.background = window.getComputedStyle(elem).backgroundColor;
										});
									}
								},
								buttons: [
									{
										text: t('commit'), icons: { primary: 'ui-icon-clock' }, id: 'button_save', click: function () {
											spentTimeCommentDialog.dialog('close');
											//
											$object.ajax = true;
											$updateResponse = $.ajax(
												'/time_entries/' + $id + '.json', 
												{
													method: 'PUT',
													data: JSON.stringify({
														time_entry: {
															hours: form.find('#time_entry_hours').val(),
															invoice_hours: form.find('#time_entry_invoice_hours').val(),
															comments: form.find('#time_entry_comment').val(),
															custom_field_values: {
																40: form.find('#time_entry_intern_comment').val()
															}
														}
													}),
													contentType: 'application/json',
													dataType : "text",
													headers: {
														'X-Redmine-API-Key': $object.api_key,
													}
												}
											)
											.done(function (response) {
												if($('#time-entry-' + $id).find('td.hours').length > 0){
													$('#time-entry-' + $id).find('td.hours').text(form.find('#time_entry_hours').val());
												}
												if($('#time-entry-' + $id).find('td.invoice_hours').length > 0){
													$('#time-entry-' + $id).find('td.invoice_hours').text(form.find('#time_entry_invoice_hours').val());
												}
												if($('#time-entry-' + $id).find('td.comments').length > 0){
													$('#time-entry-' + $id).find('td.comments').html(form.find('#time_entry_comment').val().replace(/\r?\n/g, '<br />'));
												}
												if($('#time-entry-' + $id).find('td.cf_40').length > 0){
													$('#time-entry-' + $id).find('td.cf_40').html(form.find('#time_entry_intern_comment').val().replace(/\r?\n/g, '<br />'));
												}
												$object.ajax = false;
											})
											.fail(function ($xhr) {
												if($xhr.status != 200){
													var alertText = '';
													if($xhr.responseJSON){
														if($xhr.responseJSON.errors){
															$xhr.responseJSON.errors.forEach(function(element) {
																alertText += element + "\n";
															});
															alert(alertText);
														}
													}
												}
												$object.ajax = false;
											});
										}
									},
									{
										text: t('close'), icons: { primary: 'ui-icon-close' }, id: 'button_close', click: function () {
											spentTimeCommentDialog.dialog('close');
										}
									}
								]
							});


						})
						.fail(function ($xhr) {
							var alertText = '';
							if($xhr.responseJSON.errors){
								$xhr.responseJSON.errors.forEach(function(element) {
									alertText += element + "\n";
								});
								alert(alertText);
							}
							$object.ajax = false;
						});
					}
				}
			});
		});
	}

	return {
		setPlugin: function(plugin){
			setPlugin(plugin);
		},
		setLang: function(lang){
			setLang(lang);
		},
		setUserId: function(user){
			setUserId(user);
		},
		setApiKey: function(key){
			setApiKey(key);
		},
		setApiUrl: function(url){
			setApiUrl(url);
		},
		setLanguage: function(language){
			setLanguage(language);
		},
        init: function () {
			init();
		}
	}
}();
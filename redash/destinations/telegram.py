import logging

from redash.destinations import *

import requests
import urllib
import datetime
import os
import ast


class Telegram(BaseDestination):

    @classmethod
    def configuration_schema(cls):
        return {
            "type": "object",
            "properties": {
                "chat_id": {
                    "type": "string",
                    "title": "Chat ID"
                },
                "allow_back_to_normal": {
                    "type": "string",
                    "title": "Allow \"BACK TO NORMAL\" notifications?\nIt will be sent when the alert goes from "
                             "\"TRIGGERED\" status to \"OK\" status.\n(yes/no, case insensitive)",
                    "default": "no"
                },
                "allow_download_links": {
                    "type": "string",
                    "title": "Allow query result download links in notifications?\nQuery result download is available "
                             "in .csv, .xlsx, and .json files.\nOnly privileged logged-in users can download the "
                             "files.\n(yes/no, case insensitive)",
                    "default": "no"
                },
                "short_mode": {
                    "type": "string",
                    "title": "Short, summarized notification messages (yes/no, case insensitive)",
                    "default": "no"
                }
            },
            "required": ["chat_id"]
        }

    @classmethod
    def icon(cls):
        return 'fa-bolt'

    def notify(self, alert, query, user, new_state, app, host, options):

        # Filter recipients first
        recipients_unfiltered = [chat_id for chat_id in options.get('chat_id', '').split(',') if chat_id]

        # REDASH_BOT_WHITELIST environment variable is a dictionary type
        whitelist = ast.literal_eval(os.environ.get('REDASH_BOT_WHITELIST', ''))
        # Filter recipients to only accept whitelisted chat IDs
        recipients = []
        for chat_id in recipients_unfiltered:
            if int(chat_id) in whitelist:
                recipients.append(chat_id)

        if not recipients:
            logging.warning("No valid chat ID given. Skipping send.")

        # Prepare the message and all the parameters
        domain_name = host.split('.')[0].replace("https://", "")
        current_date = str(datetime.datetime.utcnow())

        if str(options.get('short_mode')).lower() == "yes":
            essence = self.shortmode(query, app, host)
        else:
            essence = self.longmode(query, app, host)

        send = True

        if new_state == "triggered":
            essence = essence.format(alert_name=alert.name, domain_name=domain_name, host=host, alert_id=alert.id,
                                     state="TRIGGERED", date=current_date, query_id=query.id)
        else:
            if str(options.get('allow_back_to_normal')).lower() == "yes":
                essence = essence.format(alert_name=alert.name, domain_name=domain_name, host=host, alert_id=alert.id,
                                         state="BACK TO NORMAL", date=current_date, query_id=query.id)
            else:
                send = False

        # Sending the alert message
        logging.debug("Notifying: %s", recipients)

        if send:
            try:
                token = os.environ.get('REDASH_BOT_EXTRA_SECRET_SPELL', '')
                url = "https://api.telegram.org/bot{}/".format(token)

                # Parse URL, the way it's done in python 2
                text = urllib.pathname2url(essence)

                # Send to every whitelisted recipients
                for chat_id in recipients:
                    url = url + "sendMessage?text={}&chat_id={}&parse_mode=markdown".format(text, chat_id)
                    requests.get(url)
            except Exception:
                logging.exception("Telegram send error.")

    # If shortmode option is not chosen
    @staticmethod
    def longmode(query, host, options):

        essence = "*{alert_name}* @ {domain_name}  \n[Configure alert]({host}/alerts/{alert_id})\n\n*{state}* {date} " \
                  "(UTC+0 time)\n\nQuery link:  \n{host}/queries/{query_id} "

        if str(options.get('allow_download_links')).lower() == "yes":
            result_csv = "{host}/api/queries/{query_id}/results/{result_id}.csv" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)
            result_xlsx = "{host}/api/queries/{query_id}/results/{result_id}.xlsx" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)
            result_json = "{host}/api/queries/{query_id}/results/{result_id}.json" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)

            essence += "  \nDownload query result in .csv:  \n[CSV download]({result_csv})".format(
                result_csv=result_csv)
            essence += "  \nDownload query result in .xlsx:  \n[XLSX download]({result_xlsx})".format(
                result_xlsx=result_xlsx)
            essence += "  \nDownload query result in .json:  \n[JSON download]({result_json})".format(
                result_json=result_json)

        return essence

    # If shortmode option is chosen
    @staticmethod
    def shortmode(query, host, options):

        essence = "*{alert_name}* @ {domain_name} *{state}*\n[Configure]({host}/alerts/{alert_id}) | " \
            "[Query]({host}/queries/{query_id}) "

        if str(options.get('allow_download_links')).lower() == "yes":
            result_csv = "{host}/api/queries/{query_id}/results/{result_id}.csv" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)
            result_xlsx = "{host}/api/queries/{query_id}/results/{result_id}.xlsx" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)
            result_json = "{host}/api/queries/{query_id}/results/{result_id}.json" \
                "".format(host=host, query_id=query.id, result_id=query.latest_query_data_id)

            essence += " | [CSV]({result_csv}) | [XLSX]({result_xlsx}) | [JSON]({result_json})".format(
                result_csv=result_csv, result_xlsx=result_xlsx, result_json=result_json)

        return essence


register(Telegram)

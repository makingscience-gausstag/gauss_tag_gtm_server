___TERMS_OF_SERVICE___

By creating or modifying this file you agree to Google Tag Manager's Community
Template Gallery Developer Terms of Service available at
https://developers.google.com/tag-manager/gallery-tos (or such other URL as
Google may provide), as modified from time to time.


___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "Gauss Tag S2S Template",
  "brand": {
    "id": "brand_dummy",
    "displayName": ""
  },
  "description": "",
  "containerContexts": [
    "SERVER"
  ]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "TEXT",
    "name": "customEventName",
    "displayName": "Custom Event Name",
    "simpleValueType": true
  },
  {
    "type": "TEXT",
    "name": "clientNames",
    "displayName": "Client Names Accepted",
    "simpleValueType": true,
    "canBeEmptyString": true,
    "valueHint": "Regex",
    "help": "It uses Re2 https://github.com/google/re2/wiki/Syntax"
  },
  {
    "type": "TEXT",
    "name": "eventNames",
    "displayName": "Event Names Accepted",
    "simpleValueType": true,
    "canBeEmptyString": true,
    "valueHint": "Regex",
    "help": "It uses Re2 https://github.com/google/re2/wiki/Syntax"
  },
  {
    "type": "TEXT",
    "name": "trackingId",
    "displayName": "Tracking Id",
    "simpleValueType": true,
    "valueValidators": [
      {
        "type": "NON_EMPTY"
      }
    ],
    "valueHint": "https://example.com/data"
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "headers",
    "displayName": "Request Headers",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Name",
        "name": "name",
        "type": "TEXT"
      }
    ]
  },
  {
    "type": "LABEL",
    "name": "excludeLabel",
    "displayName": "Filter Event Properties"
  },
  {
    "type": "TEXT",
    "name": "excludeRegex",
    "displayName": "Exclude With Regex",
    "simpleValueType": true,
    "canBeEmptyString": true,
    "help": "It uses Re2 https://github.com/google/re2/wiki/Syntax",
    "valueHint": "Regex"
  },
  {
    "type": "SIMPLE_TABLE",
    "name": "excludePaths",
    "displayName": "Exclude By Property Path",
    "simpleTableColumns": [
      {
        "defaultValue": "",
        "displayName": "Property Path",
        "name": "path",
        "type": "TEXT",
        "valueValidators": [
          {
            "type": "NON_EMPTY"
          }
        ]
      }
    ]
  }
]


___SANDBOXED_JS_FOR_SERVER___

const log = require('logToConsole');
const getAllEventData = require('getAllEventData');
const JSON = require('JSON');
const Object = require('Object');
const runContainer = require("runContainer");
const returnResponse = require("returnResponse");
const sendHttpRequest = require('sendHttpRequest');
const setResponseBody = require('setResponseBody');
const setResponseHeader = require('setResponseHeader');
const setResponseStatus = require('setResponseStatus');
const makeString = require("makeString");
const getClientName = require("getClientName");
const encodeUriComponent = require('encodeUriComponent');
const getContainerVersion = require('getContainerVersion');
const getRequestHeader = require('getRequestHeader');
const createRegex = require('createRegex');
const testRegex = require('testRegex');
const makeTableMap = require('makeTableMap');

const eventData = getAllEventData();
const clientName = getClientName();
const eventName = eventData.event_name || '';

log('Logging from the trigger template');
log('Data:', data);
log('Event Data:', eventData);

const MANDATORY_HEADERS = ['Origin', 'Referrer', 'Content-Type',
                            'X-Appengine-City', 'X-Appengine-Region',
                            'X-Appengine-Country', 'X-Appengine-CityLatLong'];

/*************************
  Helper functions.
*************************/
function constructPath(obj) {
  if (!Object.keys(obj).length) return '';

  const keyValues = Object.entries(obj).reduce(function (accumulator, currentValue, index) {
    if (currentValue[1]) {
      accumulator.push(encodeUriComponent(currentValue[0]) + '=' + encodeUriComponent(currentValue[1]));
    }
    return accumulator;
  }, []);
  
  return keyValues.join('&');
}

function deepCopy(obj) {
  return JSON.parse(JSON.stringify(obj));
}

function genHeaders() {
  let headers = {};
  
  if (data.headers) {
  data.headers.forEach((header) => {
    headers[header.name] = getRequestHeader(header.name);
  });
  }

  MANDATORY_HEADERS.forEach((header) => {
    headers[header] = getRequestHeader(header);
  });
  
  headers['Content-Type'] = 'application/json; charset=utf-8';

  return headers;
}

function filterObjectProperties(obj, excludedKeys, excludeRegex, parentKey) {
  excludedKeys = excludedKeys || [];
  excludeRegex = excludeRegex || createRegex('/.*/');
  parentKey = parentKey || '';

  const filteredObj = {};

  for (let key in obj) {
    if (obj.hasOwnProperty(key)) {
      const fullPath = parentKey + key;
      if (excludedKeys.indexOf(fullPath) === -1 && !testRegex(excludeRegex, fullPath)) {
        const value = obj[key];
        if (typeof value === 'object' && value !== null) {
          // Recursively filter nested objects
          const nestedFilteredObj = filterObjectProperties(value, excludedKeys, excludeRegex, fullPath + '.');
          if (Object.keys(nestedFilteredObj).length > 0) {
            filteredObj[key] = nestedFilteredObj;
          }
        } else {
          filteredObj[key] = value;
        }
      }
    }
  }

  return filteredObj;
}
/*************************
*************************/

const clientNamesRegex = createRegex(data.clientNames);
const eventNamesRegex = createRegex(data.eventNames);

if (testRegex(clientNamesRegex, clientName) &&
    testRegex(eventNamesRegex, eventName) &&
    eventName !== data.customEventName
   ) {
  const headers = genHeaders();
  const excludeRegex = createRegex(data.excludeRegex);
  const filteredData = filterObjectProperties(eventData, data.excludePaths, excludeRegex);
  const customData = {
    "type": "GTM-S2S",
    "container": getContainerVersion(),
    "template": "Gauss Tag S2S Template",
    "client_name": clientName,
    "event_name": eventData.event_name,
    "headers": headers,
    "data": filteredData
  };

  const body = JSON.stringify(customData);
  
  // Sends a POST request and nominates response based on the response to the POST
  // request.
  sendHttpRequest(data.trackingId,
                  {
    method: 'POST',
    timeout: 5000,
    headers: headers,
  }, body)
  .then((result) => {
    log('Requests result:', result);

    let customEvent = deepCopy(eventData);
    customEvent.event_name = data.customEventName;
    customEvent.clientName = clientName;
    
    customEvent.clientId = result.clientId;
    customEvent.v = result.v;
    customEvent.scorer_processing_time = result.scorer_processing_time;
    customEvent.base_processing_time = result.base_processing_time;
    
    runContainer(customEvent, () => returnResponse());
    // Call data.gtmOnSuccess when the tag is finished.
    data.gtmOnSuccess();
  })
  .catch((error) => {
    log('Encountered error:', error);
    data.gtmOnFailure();
  });
} else {
  log("Event name matched the exclusion, so doing nothing.");
  data.gtmOnSuccess();
}


___SERVER_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "access_response",
        "versionId": "1"
      },
      "param": [
        {
          "key": "writeResponseAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "writeHeaderAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "send_http",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedUrls",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "return_response",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_event_data",
        "versionId": "1"
      },
      "param": [
        {
          "key": "eventDataAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_container_data",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "run_container",
        "versionId": "1"
      },
      "param": []
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_request",
        "versionId": "1"
      },
      "param": [
        {
          "key": "requestAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "headerAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queryParameterAccess",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

Created on 7/3/2023, 2:56:50 PM



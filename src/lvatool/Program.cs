//*********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// This code is licensed under the MIT License (MIT).
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//*********************************************************
using System;
using System.IO;
using System.Threading.Tasks;
using System.Net.Http;
using System.Text;
using Microsoft.Azure.Devices;
using Newtonsoft.Json;
using Newtonsoft.Json.Linq;
using Azure.Messaging.EventHubs.Consumer;


namespace lvaconsole
{
    class Program
    {                
        public enum Action {
            None = 0,
            Help,
            ReadEvents,
            RunOperations
        }
        public enum LogLevel
        {
            None = 0,
            Error,
            Information,
            Warning,
            Verbose
        }
        static ServiceClient serviceClient = null;
        static string connectionString;
        static string deviceId;
        static string moduleId;
        static string firstOperation;
        static string lastOperation;
        static bool waitforinput = false;
        static string operationsPath;
        static string errorMessage; 
        static int timeOut;
        static bool all;
        static Action action;
        private const string lvaVersion = "1.0";
        private static string ErrorMessagePrefix = "Error message: {0}";
        private static string InformationMessagePrefix = "lvatool:\r\n" + "Version: {0} \r\n" + "Syntax:\r\n" +
            "lvatool --runoperations --connectionstring <IoTHubConnectionString> --device <deviceId> \r\n" +
            "                       [--module <moduleId> --operationspath <OperationsPath> --firstoperation <OperationName>]\r\n" +
            "                       [--lastoperation <OperationName> --waitforinput]\r\n" +
            "lvatool --readevents    --connectionstring <IoTHubConnectionString>\r\n" +
            "                       [--timeout <TimeOut in milliseconds> --all]\r\n" +
            "lvatool --help"+
            "Note:\r\nmoduleId default value: lvaEdge\r\nOperationPath default value: operations.json\r\nFirst Operation Name default value: null\r\nTimeOut default value: 0";

        private static object _MessageLock= new object();
        private static void LogMessage(LogLevel level, string Message)
        {
            string Text = string.Empty;
            lock (_MessageLock) {
            Console.ForegroundColor = ConsoleColor.White;
            Console.Write(string.Format("{0:d/M/yyyy HH:mm:ss.fff} ", DateTime.Now));
            if (level == LogLevel.Error)
                Console.ForegroundColor = ConsoleColor.Red;
            else if (level == LogLevel.Warning)
                Console.ForegroundColor = ConsoleColor.Yellow;
            if(string.IsNullOrEmpty(Text))
                Text = $"{Message} \r\n";
            Console.Write(Text);
            Console.ResetColor();
            }
        }
        public static async Task<int> ReadEvents(string connectionString, int timeOut, bool all)
        {
            try
            {
                if(string.IsNullOrEmpty(connectionString))
                    LogMessage(LogLevel.Error,"IoT Hub Connection String not set");


                // Translate the connection string.

                LogMessage(LogLevel.Information,"Requesting Event Hubs connection string...");
                var eventHubsConnectionString = await lvatool.IotHubConnection.RequestEventHubsConnectionStringAsync(connectionString);

                LogMessage(LogLevel.Information,"Connecting to Event Hubs...");
                await using var consumer = new EventHubConsumerClient(EventHubConsumerClient.DefaultConsumerGroupName, eventHubsConnectionString);

                // Read events from any partition of the Event Hub; once no events are read after a couple of seconds, stop reading.
                LogMessage(LogLevel.Information,"Reading events...");

                DateTime start = DateTime.UtcNow;
                await foreach (var partitionEvent in consumer.ReadEventsAsync(new ReadEventOptions { MaximumWaitTime = TimeSpan.FromMilliseconds(500) }))
                {
                    if (partitionEvent.Data != null)
                    {
                        object device;
                        object module;
                        object eventTime;
                        string deviceString = string.Empty;
                        string moduleString = string.Empty;
                        string eventTimeString = string.Empty;
                        string PartitionId = partitionEvent.Partition.PartitionId;
                        partitionEvent.Data.SystemProperties.TryGetValue("iothub-connection-device-id", out device);
                        partitionEvent.Data.SystemProperties.TryGetValue("iothub-connection-module-id", out module);
                        partitionEvent.Data.SystemProperties.TryGetValue("iothub-enqueuedtime", out eventTime);
                        if (device != null)
                            deviceString = device.ToString();
                        if (module != null)
                            moduleString = module.ToString();
                        if (eventTime != null)
                            eventTimeString = eventTime.ToString();

                        bool displayEvent = true;
                        if (all != true)
                        {
                            displayEvent = false;
                            DateTime eventDateTime = DateTime.UtcNow;
                            bool dateValid = DateTime.TryParse(eventTimeString, out eventDateTime);
                            if ((dateValid == true) && (eventDateTime > start))
                                displayEvent = true;                                   
                        }
                        if (displayEvent == true)
                        {
                            //Console.WriteLine($"\tRead an event from partition { partitionEvent.Partition.PartitionId }");                        
                            using (var stream = partitionEvent.Data.EventBody.ToStream())
                            {
                                long Len = stream.Length;
                                byte[] ArrayBuffer = new byte[Len];

                                if (Len == stream.Read(ArrayBuffer, 0, (int)Len))
                                {
                                    string result = System.Text.Encoding.UTF8.GetString(ArrayBuffer);
                                    LogMessage(LogLevel.Information, $"PartitionId [{PartitionId}] Device [{deviceString}] Module [{moduleString}]\r\nUTCTime [{eventTimeString}]  Event body: \r\n{result}");
                                }
                            }
                        }
                    }
                    else
                    {                     
                        if(((DateTime.UtcNow - start).TotalMilliseconds > timeOut) || (timeOut == 0))
                            break;

                        if( Console.KeyAvailable && ((Console.ReadKey(true).Key == ConsoleKey.Escape) || (Console.ReadKey(true).Key == ConsoleKey.Spacebar))) 
                        {
                            break;
                        }

                    }                            
                }
                LogMessage(LogLevel.Information, "Stop reading events...");
            }
            catch (Exception ex)
            {
                LogMessage(LogLevel.Error,$"An exception of type { ex.GetType().Name } occurred.  Message:{ Environment.NewLine }\t{ ex.Message }");
                return -1;
            }
            return 0;
        }
        public static async Task<int> RunOperations(string connectionString, string operationsPath, string deviceId, string moduleId, string firstOperation, string lastOperation, bool waitforinput)
        {
            try
            {
                if(string.IsNullOrEmpty(connectionString))
                    LogMessage(LogLevel.Error,"IoT Hub Connection String not set");
                if(string.IsNullOrEmpty(deviceId))
                    LogMessage(LogLevel.Error,"deviceId not set");
                if(string.IsNullOrEmpty(moduleId))
                    LogMessage(LogLevel.Error,"moduleId not set");

                LogMessage(LogLevel.Information,"Running operation...");
                serviceClient = ServiceClient.CreateFromConnectionString(connectionString);
                // Read operations json and deserialize it in to a dynamic object
                string operationsJson = File.ReadAllText(operationsPath);
                dynamic operationsObject = JsonConvert.DeserializeObject(operationsJson);

                // Read  API version property
                JProperty apiVersionProperty = new JProperty("@apiVersion", operationsObject.apiVersion);                            

                bool firstOperationReached = true;
                bool lastOperationReached = false;
                if(!string.IsNullOrEmpty(firstOperation))
                    firstOperationReached = false;
                // Loop through the operations
                foreach(var op in operationsObject.operations)
                {                 
                    string operationName = op.opName;


                    var operationParams = op.opParams;
                    if(firstOperationReached == false){
                        if(firstOperation == operationName){
                            LogMessage(LogLevel.Information,$"First Operation reached: {operationName}");
                            firstOperationReached = true;
                        }
                    }
                    //LogMessage(LogLevel.Information,$"Current Operation: {operationName}-{firstOperationReached}-{lastOperationReached}");
                    if((firstOperationReached == true)&&(lastOperationReached == false))
                    {
                        PrintMessage("\n--------------------------------------------------------------------------\n", ConsoleColor.Cyan);
                        Console.WriteLine("Executing operation " + operationName);
                        switch(operationName)
                        {
                            case "GraphTopologySet" :      
                                await ExecuteGraphTopologySetOperationAsync(operationParams, apiVersionProperty);
                                break;

                            case "GraphTopologyList" :
                            case "GraphInstanceList" :
                            case "GraphInstanceActivate" :
                            case "GraphInstanceDeactivate" :
                            case "GraphInstanceDelete" :
                            case "GraphInstanceGet" :
                            case "GraphInstanceSet" :
                            case "GraphTopologyDelete" :
                            case "GraphTopologyGet" :
                                await ExecuteGraphOperationAsync(operationParams, operationName, apiVersionProperty);
                                break;

                            case "WaitForInput" :   
                                if(waitforinput)
                                {                         
                                    PrintMessage(operationParams.message.ToString(), ConsoleColor.Yellow);
                                    Console.ReadLine();
                                }
                                break;

                            default :
                                PrintMessage("Unknown operation " + op.name, ConsoleColor.Red);                            
                                Console.WriteLine("Press Enter to continue");
                                Console.ReadLine();
                                break;
                        }                        
                        if(lastOperationReached == false){
                            if(lastOperation == operationName){
                                LogMessage(LogLevel.Information,$"Last Operation reached: {operationName}");
                                lastOperationReached = true;
                            }
                        }
                        if( Console.KeyAvailable ) 
                        {
                            char c = Console.ReadKey().KeyChar ;
                            if(c == 0x20 || c == 0x1B )
                                break;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                LogMessage(LogLevel.Error,$"An exception of type { ex.GetType().Name } occurred.  Message:{ Environment.NewLine }\t{ ex.Message }");
                return -1;
            }
            return 0;
        }

        public static async Task<int> Main(string[] args)
        {

            if(args!=null)
            {
                int i = 0;

                errorMessage = string.Empty;
                timeOut = 0;
                all = false;
                moduleId = "lvaEdge";
                deviceId = string.Empty;
                connectionString = string.Empty;
                firstOperation = string.Empty;
                lastOperation = string.Empty;
                waitforinput = false;
                action = Action.Help;

                operationsPath = "operations.json";
                while ((i < args.Length)&&(string.IsNullOrEmpty(errorMessage)))
                {
                    switch(args[i++])
                    {
                        case "--help":
                        action = Action.Help;
                        break;
                        case "--readevents":
                        action = Action.ReadEvents;
                        break;
                        case "--runoperations":
                        action = Action.RunOperations;
                        break;
                        case "--firstoperation":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                firstOperation = args[i++];
                            else
                            {
                                errorMessage = "First Operation not set";
                                action = Action.Help;
                            }
                        break;
                        case "--lastoperation":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                lastOperation = args[i++];
                            else
                            {
                                errorMessage = "last Operation not set";
                                action = Action.Help;
                            }
                        break;                        
                        case "--waitforinput":
                            waitforinput = true;
                        break;                        
                        case "--all":
                            all = true;
                        break;                        
                        case "--operationspath":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                operationsPath = args[i++];
                            else
                            {
                                errorMessage = "Operations Path not set";
                                action = Action.Help;
                            }
                        break;                        
                        case "--timeout":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                            {
                                int loop = 0;
                                if (int.TryParse(args[i++], out loop))
                                    timeOut = loop;
                                else
                                {
                                    errorMessage = "TimeOut value incorrect";
                                    action = Action.Help;
                                }
                            }
                            else
                            {
                                errorMessage = "TimeOut not set";                        
                                action = Action.Help;
                            }
                        break;
                        case "--connectionstring":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                connectionString = args[i++];
                            else
                            {
                                errorMessage = "Iot Hub connection string not set";                        
                                action = Action.Help;
                            }
                        break;
                        case "--module":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                moduleId = args[i++];
                            else
                            {
                                errorMessage = "moduleId not set";                         
                                action = Action.Help;
                            }
                        break;
                        case "--device":
                            if ((i < args.Length) && (!string.IsNullOrEmpty(args[i])))
                                deviceId = args[i++];
                            else
                            {
                                errorMessage = "deviceId not set";                         
                                action = Action.Help;
                            }
                        break;
                        default:
                            if ((args[i - 1].ToLower() == "dotnet") ||
                                (args[i - 1].ToLower() == "lvatool") ||
                                (args[i - 1].ToLower() == "lvatool.dll") ||
                                (args[i - 1].ToLower() == "lvatool.exe"))
                                break;
                            errorMessage = $"wrong parameter: {args[i-1]} ";
                            action = Action.Help;
                        break;                        
                    }
                }
            
                if(action == Action.ReadEvents)
                {
                    if(string.IsNullOrEmpty(connectionString))
                    {
                        errorMessage = $"IoT Hub Connection String not set ";
                        action = Action.Help;
                    }
                    else                    
                        return await ReadEvents(connectionString,timeOut,all);
                }
                else if(action == Action.RunOperations)
                {
                    if(string.IsNullOrEmpty(connectionString))
                    {
                        errorMessage = $"IoT Hub Connection String not set ";
                        action = Action.Help;
                    }
                    else if(string.IsNullOrEmpty(deviceId))
                    {
                        errorMessage = $"deviceId  not set ";
                        action = Action.Help;
                    }
                    else
                        return await RunOperations(connectionString, operationsPath, deviceId, moduleId, firstOperation, lastOperation, waitforinput);                    
                }
                if(action == Action.Help)
                {
                    if(!string.IsNullOrEmpty(errorMessage))
                        Console.Write(string.Format(ErrorMessagePrefix,errorMessage));
                    Console.Write(string.Format(InformationMessagePrefix,lvaVersion));
                    return 1;
                }

            }
            return 1;
        }
    
        static void PrintMessage(string message, ConsoleColor color)
        {
            Console.ForegroundColor = color;
            Console.WriteLine(message);
            Console.ResetColor();
        }

        static async Task ExecuteGraphTopologySetOperationAsync(JObject operationParams, JProperty apiVersionProperty)
        {
            try
            {
                if (operationParams == null)
                {
                    PrintMessage("opParams object is missing", ConsoleColor.Red);
                    PrintMessage("Press Enter to continue", ConsoleColor.Yellow);
                    Console.ReadLine();
                }
                else
                {
                    if (operationParams["topologyUrl"] != null)
                    {
                        // Download the MediaGraph topology JSON and invoke GraphTopologySet
                        string topologyJson = await DownloadFromUrlAsync((string)operationParams["topologyUrl"]);                        
                        await InvokeMethodWithPayloadAsync("GraphTopologySet", topologyJson);
                    }
                    else if (operationParams["topologyFile"] != null)
                    {
                        // Read the topology JSON from the file and invoke GraphTopologySet
                        string topologyJson = File.ReadAllText((string)operationParams["topologyFile"]);                        
                        await InvokeMethodWithPayloadAsync("GraphTopologySet", topologyJson);
                    }
                    else
                    {
                        PrintMessage("Neither topologyUrl nor topologyFile specified", ConsoleColor.Red);
                        PrintMessage("Press Enter to continue", ConsoleColor.Yellow);
                        Console.ReadLine();
                    }
                }
            }
            catch(Exception ex)
            {
                PrintMessage(ex.ToString(), ConsoleColor.Red);
            }
        }

        static async Task ExecuteGraphOperationAsync(JObject operationParams, string operationName, JProperty apiVersionProperty)
        {
            try
            {
                if (operationParams == null)
                {
                    PrintMessage("opParams object is missing", ConsoleColor.Red);
                    PrintMessage("Press Enter to continue", ConsoleColor.Yellow);
                    Console.ReadLine();
                }
                else
                {                
                    JObject lvaGraphObject = operationParams;
                    lvaGraphObject.AddFirst(apiVersionProperty);                                
                    await InvokeMethodWithPayloadAsync(operationName, lvaGraphObject.ToString());
                }
            }
            catch(Exception ex)
            {
                PrintMessage(ex.ToString(), ConsoleColor.Red);
            }
        }


        static async Task<string> DownloadFromUrlAsync(string url)   
        {
            string fileText = null;
            using (var httpClient = new HttpClient())
            {
                // Download the file
                using (var result = await httpClient.GetAsync(url))
                {
                    if (result.IsSuccessStatusCode)
                    {
                        byte[] bytesArray = await result.Content.ReadAsByteArrayAsync();
                        fileText = Encoding.UTF8.GetString(bytesArray);                        
                    }
                    else
                    {
                        Console.ForegroundColor = ConsoleColor.Red;
                        Console.WriteLine("Could not download from " + url);
                        Console.ResetColor();
                    }

                }
            }                

            return fileText;
        }

        static async Task InvokeMethodWithPayloadAsync(string methodName, string payload)
        {
            // Create a direct method call
            var methodInvocation = new CloudToDeviceMethod(methodName)
            { 
                ResponseTimeout = TimeSpan.FromSeconds(30)
            }
            .SetPayloadJson(payload);

            // Invoke the direct method asynchronously and get the response from the device.
            Console.ForegroundColor = ConsoleColor.Cyan;
            Console.WriteLine($"\n-----------------------  Request: {methodName}  --------------------------------------------------\n");
            Console.ResetColor();
            Console.WriteLine(JToken.Parse(payload).ToString());            

            var response = await serviceClient.InvokeDeviceMethodAsync(deviceId, moduleId, methodInvocation);
            var responseString = response.GetPayloadAsJson();

            if (response.Status >= 400)
            {
                Console.ForegroundColor = ConsoleColor.Red;
            }
            else
            {
                Console.ForegroundColor = ConsoleColor.Cyan;
            }
            
            Console.WriteLine($"\n---------------  Response: {methodName} - Status: {response.Status}  ---------------\n");
            Console.ResetColor();

            if (responseString != null)
            {
                Console.WriteLine(JToken.Parse(responseString).ToString());
            }
            else
            {
                Console.WriteLine(responseString);
            }
        }

    }
}

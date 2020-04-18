﻿using Newtonsoft.Json;
using System;
using System.Net;
using System.IO;
using System.Linq;
using System.Security.Cryptography.X509Certificates;
using Org.BouncyCastle.X509;
using Org.BouncyCastle.Utilities;
using Org.BouncyCastle.Math;
using Org.BouncyCastle.Security;
using Org.BouncyCastle.Asn1.X509;
using Org.BouncyCastle.Crypto;
using Org.BouncyCastle.Crypto.Generators;
using Org.BouncyCastle.Crypto.Operators;
using Org.BouncyCastle.Crypto.Parameters;
using Org.BouncyCastle.Pkcs;
using System.Collections;
using Org.BouncyCastle.Asn1;
using System.Security.Cryptography;
using System.Net.Http;
using System.Text;
using System.Net.Http.Headers;
using System.Threading.Tasks;
using System.Threading;
using Org.BouncyCastle.OpenSsl;

namespace ConsoleApp1


{
    class Program
    {

        internal static class Constants
        {
            public const string DockerEndpointBaseUriString = "npipe://./pipe/docker_engine";
            public const string KubernetesServiceAccountTokenFilPath = @"/var/run/secrets/kubernetes.io/serviceaccount/token";
            public const string KubernetesServiceAccountCACertFilPath = @"/var/run/secrets/kubernetes.io/serviceaccount/ca.crt";


            // omsagent secret (LA workspace Id, key and domain name)
            public const string OmsAgentSecretDir = @"C:\ProgramData";

            public const string WorkspaceKeyFileName = "KEY";
            public const string WorkspaceIdFileName = "WSID";
            public const string WorkspaceDomain = "DOMAIN";


            public const UInt64 BYTESPERMB = 1048576;
            public const UInt64 CPUTICS = 1000000000;
            public const int KBPERMB = 1024;
            public const int CONTAINER_LIST_QUERY_TIMEOUT_SECONDS = 100;
            public const int IMAGE_LIST_QUERY_TIMEOUT_SECONDS = 100;
            public const int CONTAINER_EVENTS_QUERY_TIMEOUT_SECONDS = 100;
            public const int CONTAINER_INSPECT_QUERY_TIMEOUT_SECONDS = 10;
            public const int CONTAINER_STATS_QUERY_TIMEOUT_SECONDS = 5;
            public const int CONTAINER_LOG_QUERY_TIMEOUT_SECONDS = 10;
            public const int SYTEM_INFO_QUERY_TIMEOUT_SECONDS = 5;

            public const int KUBE_SYSTEM_CONTAINER_IDs_REFRESH_INTERVAL_IN_SECONDS = 300;

            public const int CONTAINER_LOG_UPLOAD_INTERVAL_IN_SECONDS = 60;

            /// <summary>
            /// constants related to masking the secrets in container environment variable
            /// </summary>
            public static string LOGANALYTICS_CONTAINERS_MASK_ENVVAR_NAME = "LOGANALYTICS_CONTAINERS_MASK_ENVVAR_VALUE_REGEX_LIST";
            public static string LOGANALYTICS_CONTAINER_MASKED_VALUE = "[EXCLUDED-BY-CONTAINERMONITORING]";

            public const string CONTAINER_LOG_DATA_TYPE = "CONTAINER_LOG_BLOB";
            public const string CONTAINER_INSIGHTS_IP_NAME = "ContainerInsights";

            public const string DEFAULT_LOG_ANALYTICS_WORKSPACE_DOMAIN = "opinsights.azure.com";

            public const string DEFAULT_SIGNATURE_ALOGIRTHM = "SHA256WithRSA";
        }

        private static X509Certificate2 CreateSelfSignedCertificate(string agentGuid, string logAnalyticsWorkspaceId)
        {
            var random = new SecureRandom();

            var certificateGenerator = new X509V3CertificateGenerator();

            var serialNumber = BigIntegers.CreateRandomInRange(BigInteger.One, BigInteger.ValueOf(Int64.MaxValue), random);

            certificateGenerator.SetSerialNumber(serialNumber);

            var dirName = string.Format("CN={0}, CN={1}, OU=Linux Monitoring Agent, O=Microsoft", logAnalyticsWorkspaceId, agentGuid);

            X509Name certName = new X509Name(dirName);

            certificateGenerator.SetIssuerDN(certName);

            certificateGenerator.SetSubjectDN(certName);

            certificateGenerator.SetNotBefore(DateTime.UtcNow.Date);

            certificateGenerator.SetNotAfter(DateTime.UtcNow.Date.AddYears(1));

            const int strength = 2048;

            var keyGenerationParameters = new KeyGenerationParameters(random, strength);

            var keyPairGenerator = new RsaKeyPairGenerator();

            keyPairGenerator.Init(keyGenerationParameters);

            var subjectKeyPair = keyPairGenerator.GenerateKeyPair();

            certificateGenerator.SetPublicKey(subjectKeyPair.Public);


            // Get Private key for the Certificate
            TextWriter textWriter = new StringWriter();
            PemWriter pemWriter = new PemWriter(textWriter);
            pemWriter.WriteObject(subjectKeyPair.Private);
            pemWriter.Writer.Flush();

            string privateKeyString = textWriter.ToString();


            // The magic extension that on commenting made the certificate work with ODS!!!!!

            //certificateGenerator.AddExtension(X509Extensions.ExtendedKeyUsage.Id, false,
            //  new ExtendedKeyUsage(new[] { KeyPurposeID.IdKPServerAuth, KeyPurposeID.IdKPClientAuth }));

            //certificateGenerator.AddExtension(X509Extensions.ExtendedKeyUsage.Id, false,
            //  new AuthorityKeyIdentifier(
            //      new GeneralNames(new GeneralName(certName)), serialNumber));


            //certificateGenerator.AddExtension(X509Extensions.ExtendedKeyUsage.Id, false,
            //   new AuthorityKeyIdentifier(
            //       SubjectPublicKeyInfoFactory.CreateSubjectPublicKeyInfo(subjectKeyPair.Public),
            //       new GeneralNames(new GeneralName(certName)), serialNumber));


            var issuerKeyPair = subjectKeyPair;
            var signatureFactory = new Asn1SignatureFactory(Constants.DEFAULT_SIGNATURE_ALOGIRTHM, issuerKeyPair.Private);
            var bouncyCert = certificateGenerator.Generate(signatureFactory);

            // Lets convert it to X509Certificate2
            X509Certificate2 certificate;

            Pkcs12Store store = new Pkcs12StoreBuilder().Build();

            store.SetKeyEntry($"{agentGuid}_key", new AsymmetricKeyEntry(subjectKeyPair.Private), new[] { new X509CertificateEntry(bouncyCert) });

            string exportpw = Guid.NewGuid().ToString("x");

            using (var ms = new MemoryStream())
            {
                store.Save(ms, exportpw.ToCharArray(), random);
                certificate = new X509Certificate2(ms.ToArray(), exportpw, X509KeyStorageFlags.Exportable);
            }

            // Get the value.
            string resultsTrue = certificate.ToString(true);

            // Display the value to the console.
            Console.WriteLine(resultsTrue);

            //Get Certificate in PEM format
            StringBuilder builder = new StringBuilder();
            builder.AppendLine("-----BEGIN CERTIFICATE-----");
            builder.AppendLine(
                Convert.ToBase64String(certificate.RawData, Base64FormattingOptions.InsertLineBreaks));
            builder.AppendLine("-----END CERTIFICATE-----");

            Console.WriteLine("Writing certificate and key to two files");

            string crt_location = "C://oms.crt";
            string key_location = "C://oms.key";
            try
            {
                if (!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("CI_CRT_LOCATION")))
                {
                    crt_location = Environment.GetEnvironmentVariable("CI_CRT_LOCATION");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Reading env variables (CI_CRT_LOCATION) is too much to ask for " + ex.Message);
            }

            try
            {
                if (!String.IsNullOrEmpty(Environment.GetEnvironmentVariable("CI_KEY_LOCATION")))
                {
                    key_location = Environment.GetEnvironmentVariable("CI_KEY_LOCATION");
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Reading env variables (CI_KEY_LOCATION) is too much to ask for " + ex.Message);
            }


            File.WriteAllText(crt_location, builder.ToString());
            File.WriteAllText(key_location, privateKeyString);

            // Saving certificate in the store
            // SaveCertificate(certificate);

            // For local testing : reading a random cert
            // string newcer = "E://oms.crt";
            //X509Certificate2 cert1 = new X509Certificate2(newcer);

            return certificate;
        }


        public static void SaveCertificate(X509Certificate2 certificate)
        {
            var userStore = new X509Store(StoreName.My, StoreLocation.CurrentUser);
            userStore.Open(OpenFlags.ReadWrite);
            userStore.Add(certificate);
            userStore.Close();
        }

        private static string Sign(string requestdate, string contenthash, string key)
        {
            var signatureBuilder = new StringBuilder();
            signatureBuilder.Append(requestdate);
            signatureBuilder.Append("\n");
            signatureBuilder.Append(contenthash);
            signatureBuilder.Append("\n");
            string rawsignature = signatureBuilder.ToString();

            //string rawsignature = contenthash;

            HMACSHA256 hKey = new HMACSHA256(Convert.FromBase64String(key));
            return Convert.ToBase64String(hKey.ComputeHash(Encoding.UTF8.GetBytes(rawsignature)));
        }

        public static void RegisterWithOms(X509Certificate2 cert, string AgentGuid, string logAnalyticsWorkspaceId, string logAnalyticsWorkspaceKey, string logAnalyticsWorkspaceDomain)
        {

            string rawCert = Convert.ToBase64String(cert.GetRawCertData()); //base64 binary
            string hostName = Dns.GetHostName();

            string date = DateTime.Now.ToString("O");

            string xmlContent = "<?xml version=\"1.0\"?>" +
                "<AgentTopologyRequest xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\" xmlns=\"http://schemas.microsoft.com/WorkloadMonitoring/HealthServiceProtocol/2014/09/\">" +
                "<FullyQualfiedDomainName>"
                 + hostName
                + "</FullyQualfiedDomainName>" +
                "<EntityTypeId>"
                    + AgentGuid
                + "</EntityTypeId>" +
                "<AuthenticationCertificate>"
                  + rawCert
                + "</AuthenticationCertificate>" +
                "</AgentTopologyRequest>";

            SHA256 sha256 = SHA256.Create();

            string contentHash = Convert.ToBase64String(sha256.ComputeHash(Encoding.ASCII.GetBytes(xmlContent)));

            string authKey = string.Format("{0}; {1}", logAnalyticsWorkspaceId, Sign(date, contentHash, logAnalyticsWorkspaceKey));


            HttpClientHandler clientHandler = new HttpClientHandler();

            clientHandler.ClientCertificates.Add(cert);

            var client = new HttpClient(clientHandler);

            string url = "https://" + logAnalyticsWorkspaceId + ".oms." + logAnalyticsWorkspaceDomain + "/AgentService.svc/AgentTopologyRequest";

            Console.WriteLine("OMS endpoint Url : {0}", url);

            client.DefaultRequestHeaders.Add("x-ms-Date", date);
            client.DefaultRequestHeaders.Add("x-ms-version", "August, 2014");
            client.DefaultRequestHeaders.Add("x-ms-SHA256_Content", contentHash);
            client.DefaultRequestHeaders.TryAddWithoutValidation("Authorization", authKey);
            client.DefaultRequestHeaders.Add("user-agent", "MonitoringAgent/OneAgent");
            client.DefaultRequestHeaders.Add("Accept-Language", "en-US");


            HttpContent httpContent = new StringContent(xmlContent, Encoding.UTF8);

            httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/xml");


            Console.WriteLine("sent registration request");

            Task<HttpResponseMessage> response = client.PostAsync(new Uri(url), httpContent);

            Console.WriteLine("waiting response for registration request : {0}", response.Result.StatusCode);

            response.Wait();

            Console.WriteLine("registration request processed");

            Console.WriteLine("Response result status code : {0}", response.Result.StatusCode);

            HttpContent responseContent = response.Result.Content;

            string result = responseContent.ReadAsStringAsync().Result;

            Console.WriteLine("Return Result: " + result);

            Console.WriteLine(response.Result);
        }

        public static void RegisterWithOmsWithBasicRetryAsync(X509Certificate2 cert, string AgentGuid, string logAnalyticsWorkspaceId, string logAnalyticsWorkspaceKey, string logAnalyticsWorkspaceDomain)
        {
            int currentRetry = 0;

            for (; ; )
            {
                try
                {
                    RegisterWithOms(
                       cert, AgentGuid, logAnalyticsWorkspaceId, logAnalyticsWorkspaceKey, logAnalyticsWorkspaceDomain);

                    // Return or break.
                    break;
                }
                catch (Exception ex)
                {

                    currentRetry++;

                    // Check if the exception thrown was a transient exception
                    // based on the logic in the error detection strategy.
                    // Determine whether to retry the operation, as well as how
                    // long to wait, based on the retry strategy.
                    if (currentRetry > 3)
                    {
                        // If this isn't a transient error or we shouldn't retry,
                        // rethrow the exception.
                        Console.WriteLine("exception occurred : {0}", ex.Message);
                        throw;
                    }
                }

                // Wait to retry the operation.
                // Consider calculating an exponential delay here and
                // using a strategy best suited for the operation and fault.
                Task.Delay(1000);
            }
        }

        public static X509Certificate2 RegisterAgentWithOMS(string logAnalyticsWorkspaceId,
            string logAnalyticsWorkspaceKey, string logAnalyticsWorkspaceDomain)
        {
            X509Certificate2 agentCert = null;

            var agentGuid = Guid.NewGuid().ToString("B");

            Environment.SetEnvironmentVariable("CI_AGENT_GUID", agentGuid);

            try
            {
                agentCert = CreateSelfSignedCertificate(agentGuid, logAnalyticsWorkspaceId);

                if (agentCert == null)
                {
                    throw new Exception($"creating self-signed certificate failed for agentGuid : {agentGuid} and workspace: {logAnalyticsWorkspaceId}");
                }

                Console.WriteLine($"Successfully created self-signed certificate  for agentGuid : {agentGuid} and workspace: {logAnalyticsWorkspaceId}");

                Console.WriteLine($"Agent Guid : {agentGuid}");

                RegisterWithOmsWithBasicRetryAsync(agentCert, agentGuid,
                    logAnalyticsWorkspaceId,
                    logAnalyticsWorkspaceKey,
                    logAnalyticsWorkspaceDomain);


            }
            catch (Exception ex)
            {
                Console.WriteLine("Registering agent with OMS failed : {0}", ex.Message.ToString());

                throw ex;
            }

            return agentCert;
        }

        static void Main(string[] args)
        {
            Console.WriteLine("Dotnet executable starting :");


            string logAnalyticsWorkspaceID = Environment.GetEnvironmentVariable("WSID");
            string logAnalyticsWorkspaceSharedKey = Environment.GetEnvironmentVariable("WSKEY");
            string logAnayticsDomain = Environment.GetEnvironmentVariable("DOMAIN");
            X509Certificate2 clientCertificate = RegisterAgentWithOMS(logAnalyticsWorkspaceID, logAnalyticsWorkspaceSharedKey, logAnayticsDomain);
        }

        public static void SendDataToODS_ContainerLog(X509Certificate2 cert, string logAnalyticsWorkspaceId, string logAnalyticsWorkspaceDomain, string jsonContent)
        {
            string rawCert = Convert.ToBase64String(cert.GetRawCertData()); //base64 binary
            string requestId = Guid.NewGuid().ToString("D");

            string dateTime = DateTime.Now.ToString("O");

            try
            {
                var clientHandler = new HttpClientHandler();
                clientHandler.ClientCertificates.Add(cert);
                var client = new HttpClient(clientHandler);

                string url = "https://" + logAnalyticsWorkspaceId + ".ods." + logAnalyticsWorkspaceDomain + "/OperationalData.svc/PostJsonDataItems?api-version=2016-04-01";

                Console.WriteLine("ODS endpoint url: {0}", url);

                client.DefaultRequestHeaders.Add("X-Request-ID", requestId);

                HttpContent httpContent = new StringContent(jsonContent, Encoding.UTF8);
                httpContent.Headers.ContentType = new MediaTypeHeaderValue("application/json");
                Task<HttpResponseMessage> response = client.PostAsync(new Uri(url), httpContent);

                response.Wait();
                HttpContent responseContent = response.Result.Content;
                string result = responseContent.ReadAsStringAsync().Result;
                Console.WriteLine("Return Result: " + result);
                Console.WriteLine("requestId: " + requestId);
                Console.WriteLine(response.Result);
                Console.WriteLine("Finished registration call");
                //TODO - update watermark only when the data ingestion successful
            }
            catch (Exception excep)
            {
                Console.WriteLine("ODS API Post Exception: " + excep.Message);
            }
        }


        //public static void PostContainerLogs(object state)
        //{
        //    try
        //    {

        //        var containerLogs = new ContainerLogs();
        //        var logs = containerLogs.GetContainerLogs();

        //        Console.WriteLine("Total number of log lines : {0}", logs.DataItems.Count);

        //        var json = JsonConvert.SerializeObject(logs);

        //        SendDataToODS_ContainerLog(clientCertificate,
        //            logAnalyticsWorkspaceId,
        //            logAnalyticsWorkspaceDomain,
        //            json
        //            );
        //    }
        //    catch (Exception ex)
        //    {
        //        Console.WriteLine("PostContainerLogs failed : {0}", ex.Message.ToString());
        //    }

        //    _uploadTimer.Change(
        //           TimeSpan.FromSeconds(Constants.CONTAINER_LOG_UPLOAD_INTERVAL_IN_SECONDS),
        //           TimeSpan.FromMilliseconds(-1));

        //}
    }
}

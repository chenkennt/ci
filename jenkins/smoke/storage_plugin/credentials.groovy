import com.cloudbees.plugins.credentials.CredentialsScope
import com.cloudbees.plugins.credentials.SystemCredentialsProvider
import com.microsoftopentechnologies.windowsazurestorage.helper.AzureCredentials
import com.cloudbees.plugins.credentials.domains.Domain

def cred = new AzureCredentials(
  CredentialsScope.GLOBAL,
  "storagekey",
  "key for Azure storage",
  "$STORAGE_ACCOUNT",
  "$STORAGE_KEY",
  "http://blob.core.windows.net/"
)

SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), cred)

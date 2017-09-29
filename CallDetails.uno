using Uno.Threading;
using Uno;
using Uno.UX;
using Uno.Compiler.ExportTargetInterop;
using Android;
using Uno.Permissions;
using Fuse;
using Fuse.Scripting;

[extern(Android) ForeignInclude(Language.Java, "android.app.Activity",
                                               "android.provider.CallLog",
                                               "android.database.Cursor", 
                                               "android.content.Context",
                                               "android.os.Bundle",
                                               "android.net.Uri",
                                               "java.lang.StringBuffer",
                                               "java.util.Date")]

[UXGlobalModule]
public class CallDetails : NativeModule{
    static readonly CallDetails _instance;
    static string getPermission; 

    public CallDetails(){
        if (_instance != null) return;
    	_instance = this;
    	Resource.SetGlobalKey(_instance, "CallDetails");
        AddMember(new NativeFunction("callHistory",(NativeCallback)callHistory));
    }

    object callHistory(Context c, object[] args){
        var permissionPromise = Permissions.Request(Permissions.Android.READ_CALL_LOG);
        permissionPromise.Then(OnPermitted, OnRejected);
        return getPermission;
    }

    void OnPermitted(PlatformPermission permission)
    {
         debug_log "You can access the Call_History now";
         getPermission = callHistoryImpl();
    }

    void OnRejected(Exception e)
    {
        debug_log "Blast: " + e.Message;
    }

    [Foreign(Language.Java)]
    public static extern(Android) string callHistoryImpl()
    @{
        StringBuffer sb = new StringBuffer();
        Cursor c = com.fuse.Activity.getRootActivity().getContentResolver().query(CallLog.Calls.CONTENT_URI, null,null, null, android.provider.CallLog.Calls.DATE + " DESC limit 5;");
        int number = c.getColumnIndex(CallLog.Calls.NUMBER);
        int type = c.getColumnIndex(CallLog.Calls.TYPE);
        int date = c.getColumnIndex(CallLog.Calls.DATE);
        int duration = c.getColumnIndex(CallLog.Calls.DURATION);
        sb.append("Call Details :");
        while (c.moveToNext()) {
            String phNumber = c.getString(number);
            String callType = c.getString(type);
            String callDate = c.getString(date);
            Date callDayTime = new Date(Long.valueOf(callDate));
            String callDuration = c.getString(duration);
            String dir = null;
            int dircode = Integer.parseInt(callType);
            switch (dircode) {
            case CallLog.Calls.OUTGOING_TYPE:
                dir = "OUTGOING";
                break;

            case CallLog.Calls.INCOMING_TYPE:
                dir = "INCOMING";
                break;

            case CallLog.Calls.MISSED_TYPE:
                dir = "MISSED";
                break;
            
            // case CallLog.Calls.REJECTED_TYPE; //for API level 24
            //     dir = "REJECTED";
            //     break;
            }
            sb.append("\nPhone Number:--- " + phNumber + " \nCall Type:--- "
                    + dir + " \nCall Date:--- " + callDayTime
                    + " \nCall duration in sec :--- " + callDuration);
            sb.append("\n----------------------------------");
        }
        c.close();
        String val = sb.toString();
        return val;
    
    @}      

    static extern(!Android) string callHistoryImpl(){
        debug_log("Applicatio is not supported on this platform.");
        return null;
    }

}
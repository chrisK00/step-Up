namespace stepUp.Api.Data.Entities;

public class FriendRequest
{ 
    // TODO on decline just rm the sql row. on sending req make sure theyr not friends nor do a friend invite already exist
    // when returning friendreqs sort sentdate by desc
    public string FromUserId { get; set; }
    public string ToUserId { get; set; }
    public DateTime SentDate { get; set; }
}

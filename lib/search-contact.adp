<style type=text/css>
#results_box {
    overflow: auto;
 width: 200px;
 height: 300px; 
}
</style>
<form id="searchform" method="post" action="/intranet/contacts/">
<table border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td>
      <input type="text" name="query" id="query" onKeyUp="@js_update_user_select;noquote@ document.getElementById('results_box').style.visibility='visible';" autocomplete="off" value="" />
    </td>
  </tr>
  <tr>
    <td>	   
      <div id="results_box"></div>
    </td>
  </tr>
</table>
</form>

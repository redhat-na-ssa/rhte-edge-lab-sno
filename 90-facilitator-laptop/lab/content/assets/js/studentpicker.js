let student = "";
let cluster = "";
let endpoint = "/";
var update_link = function () {
    var link = "https://hello-world-{{ site.data.login.region }}.apps." + cluster + student + ".{{ site.data.login.base_domain }}" + endpoint;
    $("#app_link").attr('href', link);
}
$("#endpoint").change(function () {
    endpoint = this.value;
    update_link();
})
$("#student").change(function () {
    student = this.value;
    update_link();
});
$("#cluster").change(function () {
    cluster = this.value;
    update_link();
});

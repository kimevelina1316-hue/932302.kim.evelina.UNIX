#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/proc_fs.h>
#include <linux/uaccess.h>
#include <linux/version.h>
#include <linux/timekeeping.h>
#include <linux/slab.h>

#define procfs_name "tsulab"


#define HALLEY_PERIHELION_1986_UTC 508318800L 

#define HALLEY_FULL_CYCLE_SECONDS 2387371560L

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Halley Lab");
MODULE_DESCRIPTION("Halley's Comet path calculation using long integer arithmetic.");

static struct proc_dir_entry *our_proc_file;

static ssize_t procfile_read(struct file *file, char __user *buffer,
                             size_t len, loff_t *offset)
{
    
    if (*offset > 0)
        return 0;

    
    s64 current_time_sec = ktime_get_real_seconds();
    
    
    s64 elapsed_sec = current_time_sec - HALLEY_PERIHELION_1986_UTC;
    
    
    if (elapsed_sec < 0) {
        elapsed_sec = 0;
    }
    if (elapsed_sec > HALLEY_FULL_CYCLE_SECONDS) {
        elapsed_sec = HALLEY_FULL_CYCLE_SECONDS;
    }

    
    s64 path_percentage = (elapsed_sec * 100L) / HALLEY_FULL_CYCLE_SECONDS;

    char msg[128];
    int msg_len;
    
    msg_len = snprintf(msg, sizeof(msg),
        "Процент пути, пройденного кометой Галлея (от 09.02.1986): %lld%%\n",
        (long long)path_percentage);

    if (msg_len < 0 || msg_len >= sizeof(msg)) {
        pr_err("tsulab: snprintf failed or buffer overflow\n");
        return -EINVAL;
    }

    
    if (copy_to_user(buffer, msg, msg_len))
        return -EFAULT;

    *offset = msg_len;
    return msg_len;
}


#if LINUX_VERSION_CODE >= KERNEL_VERSION(5,6,0)
static const struct proc_ops proc_file_fops = {
    .proc_read = procfile_read,
};
#else
static const struct file_operations proc_file_fops = {
    .read = procfile_read,
};
#endif

static int __init tsulab_init(void)
{
    pr_info("Halley's Comet path module loaded.\n"); 
    
    our_proc_file = proc_create(procfs_name, 0644, NULL, &proc_file_fops);
    if (!our_proc_file) {
        pr_alert("Error: Could not initialize /proc/%s\n", procfs_name);
        return -ENOMEM;
    }
    pr_info("/proc/%s created successfully.\n", procfs_name);
    return 0;
}

static void __exit tsulab_exit(void)
{
    remove_proc_entry(procfs_name, NULL);
    pr_info("/proc/%s removed.\n", procfs_name);
}

module_init(tsulab_init);
module_exit(tsulab_exit);